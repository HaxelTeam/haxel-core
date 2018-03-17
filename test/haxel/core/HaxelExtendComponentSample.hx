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

import haxel.core.IHaxelFactory;
class HaxelExtendComponentSample extends HaxelComponentSample {

    public var extendInitPassed:Bool;

    public var extendReleasePassed:Bool;

    public var extendHandlePassed:Bool;

    @:Inject
    private var instanceSample: HaxelComponentInstanceSample;

    @:Inject
    private var factorySample: IHaxelFactory<HaxelComponentFactoryItemSample>;

    public function new() {
        super();
        trace("buildExtendSample");
    }

    @:Init
    public function extendInitSample(): Void {
        extendInitPassed = true;
        trace("extendInitPassed");
        factorySample.create();
    }

    @:Release
    public function extendReleaseSample(): Void {
        extendReleasePassed = true;
        trace("extendReleasePassed");
    }

    @:Handle(EventSample.SAMPLE)
    public function extendsHandleSample(): Void {
        extendHandlePassed = true;
        trace("extendHandlePassed");
    }
}
