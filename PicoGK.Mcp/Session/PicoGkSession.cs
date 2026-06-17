//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK ("peacock") is a compact software kernel for computational geometry,
// specifically for use in Computational Engineering Models (CEM).
//
// For more information, please visit https://picogk.org
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with the
// License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, SOFTWARE IS
// PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.

using PicoGK;
using System.Diagnostics;
using System.Numerics;
using System.Collections.Concurrent;

namespace PicoGK.Mcp
{
    public record ObjectInfo(string Id, string Type, string Description);

    public class PicoGkSession : IDisposable
    {
        private volatile Library? _library;
        private readonly object _initLock = new();
        private readonly ConcurrentDictionary<string, ManagedObject> _objects = new();
        private readonly ConcurrentDictionary<string, int> _typeCounters = new();

        // Retry configuration for mesh-conversion-dependent queries
        // (get_bounding_box, get_volume) that can transiently fail on
        // freshly-created/transformed voxel objects due to a disposal race
        // in PicoGK's internal using-Mesh pattern.
        public int RetryMaxAttempts { get; set; } = 5;
        public int RetryInitialDelayMs { get; set; } = 10;
        public double RetryBackoffMultiplier { get; set; } = 2.0;

        public bool IsInitialized
        {
            get { lock (_initLock) return _library != null; }
        }

        public Library Library
        {
            get
            {
                lock (_initLock)
                    return _library
                        ?? throw new InvalidOperationException(
                            "PicoGK is not initialized. Call picogk_init first.");
            }
        }

        public float VoxelSizeMM => Library.fVoxelSize;

        public void Initialize(float voxelSizeMM)
        {
            lock (_initLock)
            {
                if (_library != null)
                    throw new InvalidOperationException(
                        "PicoGK is already initialized.");

                _library = new Library(voxelSizeMM);
                Library.RegisterGlobalLibrary(_library);
            }
        }

        public string Register(object obj, string? id = null, string description = "")
        {
            id ??= AutoId(obj);
            var typeName = obj.GetType().Name;
            _objects[id] = new ManagedObject(obj, typeName, description);
            return id;
        }

        public string GetId(string? requestedId, object obj, string description = "")
        {
            return Register(obj, requestedId, description);
        }

        public T Get<T>(string id) where T : class
        {
            if (!_objects.TryGetValue(id, out var entry))
                throw new KeyNotFoundException(
                    $"Object '{id}' not found. Use list_objects to see available objects.");

            if (entry.Value is T typed)
                return typed;

            throw new InvalidCastException(
                $"Object '{id}' is {entry.Type}, not {typeof(T).Name}.");
        }

        public bool TryGet<T>(string id, out T? obj) where T : class
        {
            if (_objects.TryGetValue(id, out var entry) && entry.Value is T typed)
            {
                obj = typed;
                return true;
            }
            obj = null;
            return false;
        }

        public IReadOnlyList<ObjectInfo> ListObjects()
        {
            return _objects.Select(kv =>
                new ObjectInfo(kv.Key, kv.Value.Type, kv.Value.Description)
            ).ToList();
        }

        public bool Delete(string id)
        {
            return _objects.TryRemove(id, out _);
        }

        public int DeleteMany(IEnumerable<string> ids)
        {
            int n = 0;
            foreach (var id in ids)
                if (_objects.TryRemove(id, out _))
                    n++;
            return n;
        }

        public int DeleteAllExcept(ISet<string> keepIds)
        {
            int n = 0;
            foreach (var kv in _objects)
            {
                if (!keepIds.Contains(kv.Key) && _objects.TryRemove(kv.Key, out _))
                    n++;
            }
            return n;
        }

        /// <summary>
        /// Retry an operation that depends on internal mesh conversion with
        /// exponential backoff. Certain PicoGK query operations (bounding box,
        /// volume) create a temporary mesh internally via a `using` pattern that
        /// can transiently race with concurrent disposal. This helper retries
        /// the operation until it succeeds or the timeout/attempt budget is
        /// exhausted.
        /// </summary>
        public T RetryMeshQuery<T>(Func<T> operation, string contextDescription = "")
        {
            Exception? last = null;
            int delay = RetryInitialDelayMs;
            int totalWaited = 0;
            int maxTotalMs = (int)(RetryInitialDelayMs * Math.Pow(RetryBackoffMultiplier, RetryMaxAttempts));

            for (int attempt = 0; attempt < RetryMaxAttempts; attempt++)
            {
                try
                {
                    return operation();
                }
                catch (Exception ex) when (
                    ex is KeyNotFoundException
                    || ex is ObjectDisposedException
                    || ex is InvalidOperationException
                    || ex is System.Runtime.InteropServices.ExternalException
                    || (ex.Message != null && (
                        ex.Message.Contains("not found", StringComparison.OrdinalIgnoreCase)
                        || ex.Message.Contains("not valid", StringComparison.OrdinalIgnoreCase)
                        || ex.Message.Contains("disposed", StringComparison.OrdinalIgnoreCase)
                        || ex.Message.Contains("empty", StringComparison.OrdinalIgnoreCase)
                    )))
                {
                    last = ex;
                    if (attempt < RetryMaxAttempts - 1)
                    {
                        Thread.Sleep(delay);
                        totalWaited += delay;
                        delay = (int)(delay * RetryBackoffMultiplier);
                        if (delay < 1) delay = 1;
                    }
                }
            }

            throw new InvalidOperationException(
                $"Query failed after {RetryMaxAttempts} attempts" +
                (totalWaited > 0 ? $" ({totalWaited}ms backoff)" : "") +
                (string.IsNullOrEmpty(contextDescription) ? "" : $": {contextDescription}") +
                $". Last error: {last?.Message}", last);
        }

        public bool Exists(string id) => _objects.ContainsKey(id);

        public string? ValidateId(string id, Type? expectedType = null)
        {
            if (!_objects.TryGetValue(id, out var entry))
                return $"Object '{id}' not found. Use list_objects to see available objects.";

            if (expectedType != null && !expectedType.IsAssignableFrom(entry.Value.GetType()))
                return $"Object '{id}' is {entry.Type}, not {expectedType.Name}.";

            return null;
        }

        public (T? obj, string? error) SafeGet<T>(string id) where T : class
        {
            var err = ValidateId(id, typeof(T));
            if (err != null) return (null, err);
            return ((T)_objects[id].Value, null);
        }

        private string AutoId(object obj)
        {
            var prefix = obj switch
            {
                Voxels => "voxels",
                Mesh => "mesh",
                Lattice => "lattice",
                PolyLine => "polyline",
                ScalarField => "scalar",
                VectorField => "vector",
                OpenVdbFile => "vdb",
                _ => "obj"
            };
            // Per-type counter so IDs are independent (mesh_0001 vs voxels_0001).
            int n = _typeCounters.AddOrUpdate(prefix, 1, (_, v) => v + 1);
            return $"{prefix}_{n:D4}";
        }

        public void Dispose()
        {
            _objects.Clear();
            lock (_initLock)
            {
                if (_library != null)
                {
                    Library.UnregisterGlobalLibrary();
                    _library.Dispose();
                    _library = null;
                }
            }
        }

        private record ManagedObject(object Value, string Type, string Description);
    }
}
