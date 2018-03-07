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
* An interface defines the structure of a Toxic component.
**/
@:build(haxel.core.macro.ToxicMacro.buildIToxicComponent())
@:autoBuild(haxel.core.macro.ToxicMacro.prepareToxicComponent())
@:coreType
interface IToxicComponent {
    /**
    * Makes injections to this component from a scope and registers handlers in the scope.
    *
    * @param scope a scope to register to.
    **/
    @:noCompletion
    function attach(scope:IScopeAccessor):Void;

    /**
    * Inits this component.
    *
    * @param initData a data passed to component for context based components it is a value of
    *  {@link su.per.toxic.impl.IScope#getScopeKey}.
    **/
    @:noCompletion
    function init(initData:Dynamic):Void;

    /**
    * Detaches a single component from a scope.
    *
    * @param scope a scope from which a component should be detached.
    **/
    @:noCompletion
    function detach(scope:IScopeAccessor):Void;

    /**
    * Releases this component.
    **/
    @:noCompletion
    function release():Void;
}
