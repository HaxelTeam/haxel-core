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

class HaxelComponentSample extends ThirdPartySample implements IHaxelComponent {

    public var initPassed:Bool;

    public var releasePassed:Bool;

    public var handlePassed:Bool;

    public function new() {
        super();
        trace("buildSample");
    }

    @:Init
    public function initSample(): Void {
        initPassed = true;
        trace("initPassed");
    }

    @:Release
    public function releaseSample(): Void {
        releasePassed = true;
        trace("releasePassed");
    }

    @:Handle(EventSample.SAMPLE)
    public function handleSample(): Void {
        handlePassed = true;
        trace("handlePassed");
    }
}
