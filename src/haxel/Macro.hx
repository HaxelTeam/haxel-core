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
package haxel;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class Macro {

    macro public static function iterEnum(enumTypeExpr:Expr):Expr {
        var pos = enumTypeExpr.pos;
        switch(enumTypeExpr.expr) {
            case EConst(typeExpr):
                switch(typeExpr) {
                    case CIdent(s):
                        var result = Context.getType(s);
                        switch(result) {
                            case TEnum(refEnumType, params):
                                var enumDecs:Array<Expr> = [];
                                for (enumName in refEnumType.get().names) {
                                    var eField:ExprDef = EField({expr:enumTypeExpr.expr, pos:pos}, enumName);
                                    enumDecs.push({expr:eField, pos:pos});
                                }
                                return {expr : EArrayDecl(enumDecs), pos: pos};
                            default:
                        }
                    default:
                }
            default:
        }
        Context.error("Could not get enum from expr: " + enumTypeExpr, enumTypeExpr.pos);
        return null;
    }
}