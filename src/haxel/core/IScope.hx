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
* An independent element of a Toxic aplication.
* Provides IoC, Dependency Injection, event propagation features for Toxic compontents connected with this scope.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
interface IScope {
    /**
    * Sends a note to listeners of this scope.
    *
    * @param note a not to send.
    **/
    function send(note:EnumValue):Void;

    /**
    * Sends a note to listeners of this scope with a delay.
    *
    * @param note  a not to send.
    * @param delay a delay in milliseconds after which a note should be sent.
    * @return a scope timeout object with possibility cancels this event.
    **/
    function sendAfter(note:EnumValue, delay:Int = 0):Null<IScopeTimeOut>;

    /**
    * Subscribes this scope for listening events in another scope.
    *
    * @param scope a scope to listen events from.
    **/
    function subscribe(scope:IScope):Void;

    /**
    * Unsubscribes this scope for listening events from another scope.
    *
    * @param scope a scope to stop listen events from.
    **/
    function unsubscribe(scope:IScope):Void;

    /**
    * Creates an child scope.
    *
    * @param scopeKey        the key of a scope.
    * @param connectedScopes a list of connected scopes.
    * @return a created scope.
    **/
    function createChild(scopeKey:EnumValue, connectedScopes:Array<IScope> = null):IScope;

    /**
    * Removes and releases a child scope.
    *
    * @param scope a child scope to remove.
    **/
    function removeChild(scope:IScope):Void;

    /**
    * @return the key of this scope.
    **/
    function getScopeKey():EnumValue;

    /**
    * Releases this scope and all Toxic components created with this scope.
    **/
    function release():Void;

    /**
    * Checks is this scope released or not.
    *
    * @return true if scope is released and false otherwise.
    **/
    function isReleased():Bool;
}
