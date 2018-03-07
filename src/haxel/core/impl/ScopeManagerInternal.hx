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
* A manager which manages events between scopes inside a Toxic application.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class ScopeManagerInternal {
    /**
    * A list of delayed notes.
    **/
    private var delayedStackNotes: Array<{scope: IScope, command: ScopeCommand}>;

    /**
    * The current count of a lock acquirements.
    **/
    private var acquireCount: Int = 0;

    /**
    * A config of a Toxic applicaiton associated with this manager.
    **/
    private var config: Config;

    /**
    * Constructs an instance.
    *
    * @param config a config of an Toxic application.
    **/
    public function new(config: Config) {
        this.config = config;
        delayedStackNotes = [];
    }

    /**
    * @return a config of a Toxic applicaiton associated with this manager.
    **/
    public function getConfig(): Config {
        return this.config;
    }

    /**
    * Acquires a lock of events.
    **/
    public function lockEvents(): Void {
        this.acquireCount++;
    }

    /**
    * Release a lock of events.
    **/
    public function unlockEvents(): Void {
        this.acquireCount--;
        sendDelayed();
    }

    /**
    * Delays note until {@link this#acquireCount} becomes zero.
    *
    * @param scope a scope to which a note should sent.
    * @param note  a note to send.
    **/
    public function delayNote(scope: IScope, note: Dynamic): Void {
        delayedStackNotes.push({scope: scope, command: ScopeCommand.NOTE(note)});
    }

    /**
    * Delays release of a scope until {@link this#acquireCount} becomes zero.
    *
    * @param scope a scope which should be released.
    **/
    public function delayRelease(scope: IScope): Void {
        delayedStackNotes.push({scope: scope, command: ScopeCommand.RELEASE});
    }

    /**
    * Checks whether is events locked or not.
    **/
    public function isLocked(): Bool {
        return this.acquireCount > 0;
    }

    /**
    * Sends delayed events to theirs destinations.
    **/
    public function sendDelayed(): Void {
        var iterate = delayedStackNotes;
        delayedStackNotes = [];
        for(elem in iterate) {
            switch(elem.command) {
                case NOTE(note):
                    elem.scope.send(note);
                case RELEASE:
                    elem.scope.release();
            }
        }
    }
}
