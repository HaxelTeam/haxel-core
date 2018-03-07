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
* An interface of a factory which produces Haxel components in a scope and manages them.
*
* @param <T> the class type of a produced component.
**/
interface IHaxelFactory<T : IHaxelComponent> {
    /**
    * Creates a components.
    *
    * @return an instance of produced component.
    **/
    function create():T;

    /**
    * @return an iterator over early produced components by this factory.
    **/
    function iterator():Iterator<T>;

    /**
    * @return the amount of produced components.
    **/
    function size():Int;

    /**
    * Releases a single component produced by this factory.
    **/
    function release(component:T):Void;

    /**
    * Releases all components produced by this factory.
    **/
    function releaseAll():Void;
}
