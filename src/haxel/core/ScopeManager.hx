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
package haxel.core;

import haxel.core.impl.Scope;
import haxel.core.impl.ScopeManagerInternal;

/**
* Manages scopes inside a Haxel application.
**/
class ScopeManager {
    /**
    * A manager of events  of scopes inside a Haxel application.
    **/
    private var internalManager:ScopeManagerInternal;

    /**
    * Constructs an instance.
    *
    * @param config a config of an Haxel application.
    **/
    public function new(config:Config) {
        this.internalManager = new ScopeManagerInternal(config);
    }

    /**
    * Creates a scope whith specified key.
    *
    * @param scopeKey the key of a scope.
    **/
    public function createScope(scopeKey:EnumValue):IScope {
        return new Scope(scopeKey, internalManager, null, null);
    }
}