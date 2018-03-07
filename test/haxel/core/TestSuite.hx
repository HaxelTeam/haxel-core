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

import haxe.unit.TestRunner;

/**
* A test suite for Haxel framwork.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class TestSuite {

    static function main() {
        var runner = new TestRunner();
        runner.add(new GenerationTestCase());
        runner.run();
    }
}
