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

import haxe.Timer;

/**
* An implementation of a {@link IScopeTimeOut}.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class ScopeTimeOut implements IScopeTimeOut {
    /**
    * A timer used to schedule a note execution.
    **/
    private var timer:Timer;

    /**
    * A scope connected with this timer.
    **/
    private var scope:BaseScope;

    /**
    * A note to send after a delay.
    **/
    public var note(default, null):EnumValue;

    /**
    * Construct an instance.
    *
    * @param delay a delay in milliseconds after for a note sent.
    * @param scope the scope to which note should be sent.
    * @param note  a note to send.
    **/
    public function new(delay:Int, scope:BaseScope, note:EnumValue) {
        timer = new Timer(delay);
        timer.run = run;
        this.scope = scope;
        this.note = note;
    }

    /**
    * A timer callback used to sent a note.
    **/
    private function run():Void {
        timer.stop();
        scope.processTimeout(this);
    }

//-----------------------------------------------------------------------------
//  {@link IScopeTimeOut} implementation
//-----------------------------------------------------------------------------
    public function cancel():Void {
        timer.stop();
        scope.cancelTimeout(this);
    }
}

