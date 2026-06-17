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
using System.Numerics;
using System.Collections.Concurrent;

namespace PicoGK.Mcp
{
    public record ObjectInfo(string Id, string Type, string Description);

    public class PicoGkSession : IDisposable
    {
        private Library? _library;
        private readonly ConcurrentDictionary<string, ManagedObject> _objects = new();
        private int _autoIdCounter;

        public bool IsInitialized => _library != null;

        public Library Library => _library
            ?? throw new InvalidOperationException(
                "PicoGK is not initialized. Call picogk_init first.");

        public float VoxelSizeMM => Library.fVoxelSize;

        public void Initialize(float voxelSizeMM)
        {
            if (_library != null)
                throw new InvalidOperationException(
                    "PicoGK is already initialized.");

            _library = new Library(voxelSizeMM);
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

        public bool Exists(string id) => _objects.ContainsKey(id);

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
            return $"{prefix}_{Interlocked.Increment(ref _autoIdCounter):D4}";
        }

        public void Dispose()
        {
            _objects.Clear();
            _library?.Dispose();
            _library = null;
        }

        private record ManagedObject(object Value, string Type, string Description);
    }
}
