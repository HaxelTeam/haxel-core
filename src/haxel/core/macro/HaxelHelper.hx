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
import haxe.macro.Expr;
import haxe.macro.Type;

/**
* A type def describes an enum declaration in the code.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
typedef EnumDeclarationDef = {
    /**
    * The type on an enum.
    **/
    var type:Ref<EnumType>;

    /**
    * The name of an enum field.
    **/
    var field:String;

    /**
    * Type of params of an enum field (in case the field is constructor of an enum value).
    **/
    var params:Array<Type>;
}

/**
* A halper for Haxel code generators.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class HaxelHelper {
    /**
    * Builds a Haxel name from a name.
    *
    * @param name an original name.
    * @return a Haxel name string.
    **/
    public static function getHaxelName(name:String):String {
        return "u2620_" + name;
    }

    /**
    * Detects an enum declaration in specified expression and return a descriptor of this declaration.
    *
    * @param param an expression with enum declaration.
    * @return a detected enum declaration or null otherwise.
    **/
    public static function getEnumDecl(param:Expr):Null<EnumDeclarationDef> {
        switch(param.expr) {
            case EField(typeExpr, enumField):
                switch(typeExpr.expr) {
                    case EConst(cEnum):
                        switch(cEnum) {
                            case CIdent(s):
                                var result = Context.getType(s);
                                switch(result) {
                                    case TEnum(refEnumType, enumParams):
                                        return {type: refEnumType, field: enumField, params: enumParams};
                                    default:
                                        return null;
                                }
                            default:
                                return null;
                        }
                    default:
                        return null;
                }
            case ECall(fieldExpr, params):
                return getEnumDecl(fieldExpr);
            default:
                return null;
        }
    }

    /**
    * Gets a type path for a Haxel library definition.
    *
    * @param name a name of a module or a definition.
    * @param sub  a name of definition in the module.
    * @return a type path to a definition.
    **/
    public static function tHaxel(name:String, ?sub:Null<String>):ComplexType {
        return TPath({sub: sub, params:[], pack:["haxel", "core"], name:name });
    }

    /**
    * Gets a type path for a Haxe base type.
    *
    * @param name a name of the base type.
    * @return a type path to a base type.
    **/
    public static function getBaseType(name:String):ComplexType {
        return TPath({sub: null, params:[], pack:[], name:name });
    }

    /**
    * @return a type path to the Void type.
    **/
    public static function tVoid():ComplexType {
        return getBaseType("Void");
    }

    /**
    * @return a type path to the Dynamic type.
    **/
    public static function tDynamic():ComplexType {
        return getBaseType("Dynamic");
    }

    /**
    * @return a type path to the EnumValue type.
    **/
    public static function tEnumValue():ComplexType {
        return getBaseType("EnumValue");
    }

    /**
    * @return a type path to the Array<Dynamic> type.
    **/
    public static function tArray():ComplexType {
        return TPath({sub: null, params:[TPType(getBaseType("Dynamic"))], pack:[], name:"Array" });
    }

    /**
    * @return a type path to the String type.
    **/
    public static function tString():ComplexType {
        return getBaseType("String");
    }

    /**
    * Detects in which generation a class implements an interface.
    *
    * @param classTypeRef  a reference to a class type to check.
    * @param interfaceType the type on an interface to check.
    * @return a number of generation of this class if a class implements the interface and <code>null</code> otherwise.
    **/
    public static function getGeneration(classTypeRef:Ref<ClassType>, interfaceType:Type):Null<Int> {
        switch(interfaceType) {
            case TInst(interfaceClassType, params):
                var generation:Int = 0;
                while (classTypeRef != null) {
                    for (interfaceDecl in classTypeRef.get().interfaces) {
                        if (Context.unify(interfaceType, TInst(interfaceDecl.t, interfaceDecl.params))) {
                            if (interfaceDecl.params.length == params.length) {
                                var paramsSame = true;
                                for (i in 0...params.length) {
                                    if (params[i] != interfaceDecl.params[i]) {
                                        paramsSame = false;
                                        break;
                                    }
                                }
                                if (paramsSame) {
                                    return generation;
                                }
                            }
                        }
                    }
                    var superClassRef = classTypeRef.get().superClass;
                    if (superClassRef == null) {
                        break;
                    }
                    generation++;
                    classTypeRef = superClassRef.t;
                }
            default:
        }
        return null;
    }

    /**
    * Retrieves type path of class declaration.
    *
    * @return a type path of a class.
    **/
    public static function getTypePath(className:String):TypePath {
        switch(Context.toComplexType(Context.getType(className))) {
            case TPath(typePath):
                return typePath;
            default:
        }
        return null;
    }

    /**
    * @return the current pos of the build context.
    **/
    public static function pos():Position {
        var clazzRef = Context.getLocalClass();
        if (clazzRef != null) {
            return clazzRef.get().pos;
        }
        return Context.currentPos();
    }

    /**
    * Builds an expression from an expression definition.
    *
    * @param def       an expression definition.
    * @param targetPos the position of an expression definition.
    * @return an expression definition.
    **/
    public static function e(def:ExprDef, ?targetPos:Position):Expr {
        if (targetPos == null) {
            targetPos = pos();
        }
        return {expr: def, pos:targetPos};
    }

    /**
    * Builds an public field definition with @:noCompletition metadata.
    *
    * @param name      the name of a field.
    * @param kind      the kind of a field definition.
    * @param targetPos the position of a field definition.
    * @return a public field definition.
    **/
    public static function f(name:String, kind:FieldType, ?targetPos:Position):Field {
        if (targetPos == null) {
            targetPos = pos();
        }
        var noCompletionMeta = {
            name: ":noCompletion",
            params: [],
            pos: targetPos
        }
        return {pos: targetPos, name: name, meta: [noCompletionMeta], kind: kind, doc: null, access: [APublic]}
    }

    /**
    * Builds an expression which calls a super Haxel method of a class.
    *
    * @param name      the original name of a method to call.
    * @param args      an array of names of a super method.
    * @param targetPos the position of an expression definition.
    **/
    public static function superHaxelCall(name:String, args:Array<String>, ?targetPos:Position):Expr {
        if (targetPos == null) {
            targetPos = pos();
        }
        var superExpr = e(EConst(CIdent("super")), targetPos);
        var methodExpr = e(EField(superExpr, getHaxelName(name)), targetPos);
        var argExprs = [];
        for (arg in args) {
            argExprs.push(e(EConst(CIdent(arg)), targetPos));
        }
        return e(ECall(methodExpr, argExprs), targetPos);
    }
}
