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

/**
* An interface defines the structure of a Toxic context.
**/
@:build(haxel.core.macro.ToxicMacro.buildIToxicContext())
@:autoBuild(haxel.core.macro.ToxicMacro.prepareToxicContext())
@:coreType
interface IToxicContext {
    /**
    * Constructs components of the context and registers them in a scope.
    *
    * @param scope a scope to register in.
    **/
    @:noCompletion
    function constructComponents(accessor:IScopeAccessor):Void;

    /**
    * Prepare components in this context.
    *
    * @param scope a scope to prepare in.
    **/
    @:noCompletion
    function prepareComponents(accessor:IScopeAccessor):Void;

    /**
    * Inits all components in this context.
    *
    * @param scopeKey the key of the scope in which this component should be init.
    **/
    @:noCompletion
    function initComponents(scopeKey:Dynamic):Void;

    /**
    * Releases all components in this context.
    **/
    @:noCompletion
    function releaseComponents():Void;
}