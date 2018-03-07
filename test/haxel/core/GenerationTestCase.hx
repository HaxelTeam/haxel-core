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

import haxel.core.HaxelScope;

class GenerationTestCase extends HaxelTestCase {

    public function testBasic() {
        //GIVEN
        config.register(HaxelScope.ROOT, HaxelContextSample);
        var root = scopeManager.createScope(HaxelScope.ROOT);
        var accessor: IScopeAccessor = cast root;
        var sample: HaxelComponentSample = accessor.getOwnInjection("haxelSmaple");
        var extendSample: HaxelExtendComponentSample = accessor.getOwnInjection("haxelExtendSmaple");

        //WHEN
        root.send(EventSample.SAMPLE);
        root.release();

        //THEN
        assertTrue(sample.initPassed);
        assertTrue(sample.handlePassed);
        assertTrue(sample.releasePassed);

        assertTrue(extendSample.initPassed);
        assertTrue(extendSample.handlePassed);
        assertTrue(extendSample.releasePassed);
        assertTrue(extendSample.extendInitPassed);
        assertTrue(extendSample.extendHandlePassed);
        assertTrue(extendSample.extendReleasePassed);
    }
}
