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
import haxel.core.macro.ToxicHelper.e;
#end

/**
* A set of function which are used to generaate a Toxic related code in macro mode.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class ToxicMacro {
    /**
    * A macro genrates body of the {@link IToxicComponent} interface.
    **/
    macro public static function buildIToxicComponent():Array<Field> {
        return [
            ToxicComponentCodeGen.buildAttachFun(),
            ToxicComponentCodeGen.buildInitFun(),
            ToxicComponentCodeGen.buildDetachFun(),
            ToxicComponentCodeGen.buildReleaseFun()
        ];
    }

    /**
    * A macro genrates an implemetation of the {@link IToxicComponent} interface.
    **/
    macro public static function prepareToxicComponent():Array<Field> {
        var generator = new ToxicComponentCodeGen();
        return generator.generate();
    }

    /**
    * A macro genrates body of the {@link IToxicContext} interface.
    **/
    macro public static function buildIToxicContext():Array<Field> {
        return [
            ToxicContextCodeGen.buildConstructFun(),
            ToxicContextCodeGen.buildPrepareFun(),
            ToxicContextCodeGen.buildInitFun(),
            ToxicContextCodeGen.buildReleaseFun()
        ];
    }

    /**
    * A macro genrates body of the {@link IToxicContext} interface.
    **/
    macro public static function prepareToxicContext():Array<Field> {
        var generator = new ToxicContextCodeGen();
        return generator.generate();
    }

    /**
    * Transforms a normal call expression to a Toxic call expression.
    * <code>
    *  //call expression
    *  some.toxicFun(param1, param2, ...);
    *  //toxic call expression
    *  some.#toxicFun(param1, param2, ...);
    * </code>
    *
    * @param a call exprression.
    * @return an expression which does a call with the Toxic prefix.
    **/
    macro public static function toxicCall(callExpression: Expr): Null<Expr> {
        switch(callExpression.expr) {
            case ECall(fieldExpr, params):
                switch(fieldExpr.expr) {
                    case EField(identExpr, toxicName):
                        switch(identExpr.expr) {
                            case EConst(CIdent(identName)):
                                var toxicFieldExpr = e(EField(identExpr, ToxicHelper.getToxicName(toxicName)));
                                return e(ECall(toxicFieldExpr, params));
                            default:
                        }
                    default:
                }
            default:
        }
        Errors.invalidToxicCallDeclaration(callExpression.pos);
        return null;
    }
}
