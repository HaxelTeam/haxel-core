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

#if macro
import haxe.macro.Expr;
import haxel.core.macro.HaxelHelper.e;
#end

/**
* A set of function which are used to generaate a Haxel related code in macro mode.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class HaxelMacro {
    /**
    * A macro genrates body of the {@link IHaxelComponent} interface.
    **/
    macro public static function buildIHaxelComponent():Array<Field> {
        return [
            HaxelComponentCodeGen.buildAttachFun(),
            HaxelComponentCodeGen.buildInitFun(),
            HaxelComponentCodeGen.buildDetachFun(),
            HaxelComponentCodeGen.buildReleaseFun()
        ];
    }

    /**
    * A macro genrates an implemetation of the {@link IHaxelComponent} interface.
    **/
    macro public static function prepareHaxelComponent():Array<Field> {
        var generator = new HaxelComponentCodeGen();
        return generator.generate();
    }

    /**
    * A macro genrates body of the {@link IHaxelContext} interface.
    **/
    macro public static function buildIHaxelContext():Array<Field> {
        return [
            HaxelContextCodeGen.buildConstructFun(),
            HaxelContextCodeGen.buildPrepareFun(),
            HaxelContextCodeGen.buildInitFun(),
            HaxelContextCodeGen.buildReleaseFun()
        ];
    }

    /**
    * A macro genrates body of the {@link IHaxelContext} interface.
    **/
    macro public static function prepareHaxelContext():Array<Field> {
        var generator = new HaxelContextCodeGen();
        return generator.generate();
    }

    /**
    * Transforms a normal call expression to a Haxel call expression.
    * <code>
    *  //call expression
    *  some.haxelFun(param1, param2, ...);
    *  //haxel call expression
    *  some.#haxelFun(param1, param2, ...);
    * </code>
    *
    * @param a call exprression.
    * @return an expression which does a call with the Haxel prefix.
    **/
    macro public static function haxelCall(callExpression: Expr): Null<Expr> {
        switch(callExpression.expr) {
            case ECall(fieldExpr, params):
                switch(fieldExpr.expr) {
                    case EField(identExpr, haxelName):
                        switch(identExpr.expr) {
                            case EConst(CIdent(identName)):
                                var haxelFieldExpr = e(EField(identExpr, HaxelHelper.getHaxelName(haxelName)));
                                return e(ECall(haxelFieldExpr, params));
                            default:
                        }
                    default:
                }
            default:
        }
        Errors.invalidHaxelCallDeclaration(callExpression.pos);
        return null;
    }
}
