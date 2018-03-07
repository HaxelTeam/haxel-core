/*
 * Copyright 2017 Dmitry Razumovskiy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package haxel;

import haxe.ds.StringMap;

class EntryMap<K, V> {

    private var map:StringMap<Entry<K, V>>;

    public function new() {
        map = new StringMap<Entry<K, V>>();
    }

    public function get(k:K):Null<V> {
        var entry = map.get(Std.string(k));
        if (entry != null) {
            return entry.value;
        }
        return null;
    }

    public function set(k:K, v:V):Void {
        return map.set(Std.string(k), new Entry<K, V>(k, v));
    }

    public function exists(k:K):Bool {
        return map.exists(Std.string(k));
    }

    public function remove(k:K):Bool {
        return map.remove(Std.string(k));
    }

    public function keys():Iterator<String> {
        return map.keys();
    }

    public function iterator():Iterator<Entry<K, V>> {
        return map.iterator();
    }

    public function toString():String {
        return Std.string(map);
    }
}

class Entry<K, V> {

    public var key(default, null):K;

    public var value(default, null):V;

    public function new(key:K, value:V) {
        this.key = key;
        this.value = value;
    }
}