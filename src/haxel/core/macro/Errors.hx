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
package haxel.core.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Position;

/**
* An utility class used to genrate compilation errors.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class Errors {

    static var INVALID_HANDLER_FORM:String = "Handler should be in form @:Handle(MyNoteEnum.MY_EVENT)";

    static var INVALID_SCOPE_FORM:String = "Scope injection should be in form @:Scope for current scope or @:Scope(MyScopeEnum.MY_PARENT_SCOPE) for parental scope";

    static var INVALID_INIT_PARAM:String = "Invalid usage of @:Init metadata (the field should be a function with one parameter maximum)";

    static var INVALID_CONTEXT_CONFIG:String = "Invalid context config declaration. The context should be declared with a @:Config(components...) metadata";

    static var INVALID_TOXIC_CALL_DECLARATION:String = "Invalid Toxic call declaration. The declaration should be in form 'some.toxicFun(params)'";

    static var INVALID_CONFIG_FLAG:String = "Invalid configuration flag definition. It should be defined in key = value form";

    static var UNKNOWN_CONFIG_FLAG:String = "Unknown config flag ";

    public static var INVALID_SCOPE_INIT:String = "Invalid scope init type";

    public static var NO_HANDLERS_FOUND_FOR_EVENT:String = "No hadlers  found for event";

    public static function invalidHandlerForm(pos:Position) {
        Context.error(INVALID_HANDLER_FORM, pos);
    }

    public static function invalidInitParam(pos:Position) {
        Context.error(INVALID_INIT_PARAM, pos);
    }

    public static function invalidContextConfigDeclaration(pos: Position) {
        Context.error(INVALID_CONTEXT_CONFIG, pos);
    }

    public static function invalidToxicCallDeclaration(pos: Position) {
        Context.error(INVALID_TOXIC_CALL_DECLARATION, pos);
    }

    public static function invalidConfigFlag(pos:Position) {
        Context.error(INVALID_CONFIG_FLAG, pos);
    }

    public static function unknownConfigFlag(pos:Position, name: String) {
        Context.error(UNKNOWN_CONFIG_FLAG + name, pos);
    }
}
