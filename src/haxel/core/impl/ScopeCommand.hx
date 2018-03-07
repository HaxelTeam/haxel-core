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
package haxel.core.impl;

/**
* An enum describes command types over a scope.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
enum ScopeCommand {
    /**
    * The type of a command which sends a note to a scope.
    *
    * @param note a not to send to a scope.
    **/
    NOTE(node: Dynamic);

    /**
    * The type of a command which releases a scope.
    **/
    RELEASE;
}