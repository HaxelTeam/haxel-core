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

import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxel.core.macro.HaxelHelper.e;

/**
* The set of flags allowed for a Haxel component configuration in a Haxel context.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
typedef ComponentConfigFlagsDef = {
    /**
    * Determines that a Haxel component should be instanciate via an {@link IHaxelFactory}.
    **/
    var useFactory:Bool;
    /**
    * Determines that a Haxel component should be instanciate on each injection.
    **/
    var newInstance:Bool;
}

/**
* A code generator is used to build implementation of a Haxel context on the macro phase.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class HaxelContextCodeGen {
    /**
    * Builds a function which constructs components of a Haxel context. (IHaxelComponent#constructsComponents).
    *
    * <code>
    *   function #constructsComponents(accessor: IScopeAccessor);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildConstructFun(?body:Expr):Field {
        var scopeType = HaxelHelper.tHaxel("IScopeAccessor");
        var scopeArg:FunctionArg = {value: null, type: scopeType, opt: false, name: "accessor"};
        var constructFun:FieldType = FFun({ret:HaxelHelper.tVoid(), params:[], expr: body, args:[scopeArg]});
        return HaxelHelper.f(HaxelHelper.getHaxelName("constructComponents"), constructFun);
    }

    /**
    * Builds a function which prepares components of a Haxel context. (IHaxelComponent#prepareComponents).
    *
    * <code>
    *   function #prepareComponents(accessor: IScopeAccessor);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildPrepareFun(?body:Expr):Field {
        var scopeType = HaxelHelper.tHaxel("IScopeAccessor");
        var scopeArg:FunctionArg = {value: null, type: scopeType, opt: false, name: "accessor"};
        var constructFun:FieldType = FFun({ret:HaxelHelper.tVoid(), params:[], expr: body, args:[scopeArg]});
        return HaxelHelper.f(HaxelHelper.getHaxelName("prepareComponents"), constructFun);
    }

    /**
    * Builds a function which initilizes components of a Haxel context. (IHaxelComponent#initComponents).
    *
    * <code>
    *   function #initComponents(scopeKey: Dynamic);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildInitFun(?body:Expr):Field {
        var scopeKeyArgs:FunctionArg = {value: null, type: HaxelHelper.tDynamic(), opt: false, name: "scopeKey"};
        var initFun:FieldType = FFun({ret:HaxelHelper.tVoid(), params:[], expr: body, args:[scopeKeyArgs]});
        return HaxelHelper.f(HaxelHelper.getHaxelName("initComponents"), initFun);
    }

    /**
    * Builds a function which releases components of a Haxel context. (IHaxelComponent#releaseComponents).
    *
    * <code>
    *   function #releaseComponents(scopeKey: Dynamic);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildReleaseFun(?body:Expr):Field {
        var releaseFun = FFun({ret:HaxelHelper.tVoid(), params:[], expr: body, args:[]});
        return HaxelHelper.f(HaxelHelper.getHaxelName("releaseComponents"), releaseFun);
    }

    /**
    * An index is used to generate unique names for comonent's fields instances.
    **/
    private static var fieldIndex:Int = 0;

    /**
    * The body of the <code>IHaxelContext#constructComponents</code> function.
    **/
    private var constructBody:Array<Expr>;

    /**
    * The body of the <code>IHaxelContext#prepareComponents</code> function.
    **/
    private var prepareBody:Array<Expr>;

    /**
    * The body of the <code>IHaxelContext#initComponents</code> function.
    **/
    private var initBody:Array<Expr>;

    /**
    * The body of the <code>IHaxelContext#releaseComponents</code> function.
    **/
    private var releaseBody:Array<Expr>;

    /**
    * The set of fileds which are keeping instances of the components registerd in the Haxel context.
    **/
    private var components:Array<Field>;

    /**
    * Construct an instance of the generator.
    **/
    public function new() {
        constructBody = [];
        prepareBody = [];
        initBody = [];
        releaseBody = [];
        components = [];
    }

    /**
    * Generates imlementation of the current Haxel context in the macro Context.
    **/
    public function generate():Array<Field> {
        var fields = Context.getBuildFields();
        for (meta in Context.getLocalClass().get().meta.get()) {
            if (meta.name == ":Config") {
                processConfig(meta.params);
                return fields.concat(components).concat([
                    buildConstructFun(e(EBlock(constructBody))),
                    buildPrepareFun(e(EBlock(prepareBody))),
                    buildInitFun(e(EBlock(initBody))),
                    buildReleaseFun(e(EBlock(releaseBody)))
                ]);
            }
        }
        Errors.invalidContextConfigDeclaration(Context.currentPos());
        return [];
    }

    /**
    * Generate bodies of the current Haxel context functions.
    *
    * @param params an array of the config entities declarations.
    **/
    private function processConfig(params:Array<Expr>):Void {
        for (param in params) {
            switch(param.expr) {
                case EConst(CIdent(className)):
                    processComponent(className, param.pos);
                case EObjectDecl(injections):
                    for (injection in injections) {
                        switch(injection.expr.expr) {
                            case EConst(CIdent(className)):
                                var field = processComponent(className, injection.expr.pos);
                                constructBody.push(
                                    buildRegisterValueInjectionExpr(injection.field, field.name, param.pos));
                            case ECall(callExpr, callParams):
                                switch(callExpr.expr) {
                                    case EConst(CIdent(className)):
                                        var flags = extractFlags(callParams);
                                        if (flags.useFactory) {
                                            constructBody.push(
                                                buildRegisterFactoryInjectionExpr(
                                                    injection.field, className, param.pos));
                                        } else if (flags.newInstance) {
                                            constructBody.push(
                                                buildRegisterInstanceInjectionExpr(
                                                    injection.field, className, param.pos));
                                        } else {
                                            var field = processComponent(className, injection.expr.pos);
                                            constructBody.push(
                                                buildRegisterValueInjectionExpr(
                                                    injection.field, field.name, param.pos));
                                        }
                                    default:
                                        Errors.invalidInitParam(injection.expr.pos);
                                }
                            default:
                                Errors.invalidInitParam(injection.expr.pos);
                        }
                    }
                default:
                    Errors.invalidInitParam(param.pos);
            }
        }
    }

    /**
    * Extracts configuration parameters for a Haxel component. The paramters should be filled in key = value form:
    *  MyComponent(someFlag, someFlag)
    *
    **/
    private function extractFlags(callParams:Array<Expr>):ComponentConfigFlagsDef {
        var flags = {
            useFactory: false,
            newInstance: false
        };
        for (param in callParams) {
            switch(param.expr) {
                case EConst(CIdent(name)):
                    if (Reflect.hasField(flags, name)) {
                        Reflect.setField(flags, name, true);
                    } else {
                        Errors.unknownConfigFlag(param.pos, name);
                    }
                default:
                    Errors.invalidConfigFlag(param.pos);
            }
        }
        return flags;
    }

    /**
    * Generates expressions which are register a component in the Haxel context.
    *
    * @param className the name of a Haxel component class.
    * @param pos       a position of the declaration in the Haxel context config.
    **/
    private function processComponent(className:String, pos:Position):Field {
        var field = buildClassField(className, pos);
        components.push(field);
        constructBody.push(buildInstantiateExpr(className, field.name, pos));
        switch(Context.getType(className)) {
            case TInst(classType, params):
                var iHaxelInterface = ComplexTypeTools.toType(HaxelHelper.tHaxel("IHaxelComponent"));
                if (HaxelHelper.getGeneration(classType, iHaxelInterface) != null) {
                    prepareBody.push(buildPrepareComponentExpr(field, pos));
                    initBody.push(buildInitComponentExpr(field, pos));
                    releaseBody.push(buildReleaseComponentExpr(field, pos));
                }
            default:
        }
        return field;
    }

    /**
    * Builds a part of the IHaxelContext#prepareComponents method body.
    * <code>
    *  this.#c123.attach(scopeAccessor);
    * </code>
    *
    * @param field a field which keeps an instance of a component.
    * @param pos   a position of the declaration in the Haxel context config.
    * @return an expresion which calls attach method of a component.
    **/
    private function buildPrepareComponentExpr(field:Field, pos:Position):Expr {
        var varExpr = e(EField(e(EConst(CIdent("this")), pos), field.name), pos);
        var prepareExpr = e(EField(varExpr, HaxelHelper.getHaxelName("attach")), pos);
        var scopeExpr = e(EConst(CIdent("accessor")));
        return e(ECall(prepareExpr, [scopeExpr]));
    }

    /**
    * Builds a part of the IHaxelContext#initComponents method body.
    * <code>
    *  this.#c123.init(scopeKey);
    * </code>
    *
    * @param field a field which keeps an instance of a component.
    * @param pos   a position of the declaration in the Haxel context config.
    * @return an expresion which calls init method of a component.
    **/
    private function buildInitComponentExpr(field:Field, pos:Position):Expr {
        var varExpr = e(EField(e(EConst(CIdent("this")), pos), field.name), pos);
        var initExpr = e(EField(varExpr, HaxelHelper.getHaxelName("init")), pos);
        var scopeKeyExpr = e(EConst(CIdent("scopeKey")));
        return e(ECall(initExpr, [scopeKeyExpr]));
    }

    /**
    * Builds a part of the IHaxelContext#releaseComponents method body.
    * <code>
    *  this.#c123.release();
    * </code>
    *
    * @param field a field which keeps an instance of a component.
    * @param pos   a position of the declaration in the Haxel context config.
    * @return an expresion which calls release method of a component.
    **/
    private function buildReleaseComponentExpr(field:Field, pos:Position):Expr {
        var varExpr = e(EField(e(EConst(CIdent("this")), pos), field.name), pos);
        var releaseExpr = e(EField(varExpr, HaxelHelper.getHaxelName("release")), pos);
        return e(ECall(releaseExpr, []));
    }

    /**
    * Builds a field which is keeping an instance of the component.
    * <code>
    *  private var #c123;
    * </code>
    *
    * @param className the name of a Haxel component class.
    * @param pos       a position of the declaration in the Haxel context config.
    * @return a private field with type of the Haxel instance.
    **/
    private function buildClassField(className:String, pos:Position):Field {
        var noCompletionMeta = {
            name: ":noCompletion",
            params: [],
            pos: pos
        }
        return {pos: pos,
            name: HaxelHelper.getHaxelName("c" + fieldIndex ++),
            meta: [noCompletionMeta],
            kind: FVar(Context.toComplexType(Context.getType(className))),
            doc: null,
            access: [APrivate]}

    }

    /**
    * Builds an expression which instantiates a component and assign to a corresponded field.
    * <code>
    *  this.#c123 = new MyComponent();
    * </code>
    *
    * @param className the name of a Haxel component class.
    * @param varName   the name of a variable in the Haxel context instance.
    * @param pos       a position of the declaration in the Haxel context config.
    * @return an expression which instantiates a component.
    **/
    private function buildInstantiateExpr(className:String, varName:String, pos:Position):Expr {
        var newExpr = e(ENew(HaxelHelper.getTypePath(className), []), pos);
        var varExpr = e(EField(e(EConst(CIdent("this")), pos), varName), pos);
        return e(EBinop(OpAssign, varExpr, newExpr));
    }

    /**
    * Builds an expression which registers an instance of a component in a scope.
    * <code>
    *  scope.registerInjection("myComponent", VALUE(this.#c123));
    * </code>
    *
    * @param name    the name of an injection of a Haxel component.
    * @param varName the name of a variable in the Haxel context instance.
    * @param pos     a position of the declaration in the Haxel context config.
    * @return an expression which registers a component.
    **/
    private function buildRegisterValueInjectionExpr(injectionName:String, varName:String, pos:Position):Expr {
        var varExpr = e(EField(e(EConst(CIdent("this")), pos), varName), pos);
        var kindExpr = e(ECall(e(EConst(CIdent("VALUE")), pos), [varExpr]), pos);
        var registerFunExpr = e(EField(e(EConst(CIdent("accessor")), pos), "registerInjection"), pos);
        return e(ECall(registerFunExpr, [e(EConst(CString(injectionName))), kindExpr]));
    }


    /**
    * Builds an expression which registers a factory of components in a scope.
    * <code>
    *  scope.registerInjection("myComponent", FACTORY(MyComponent));
    * </code>
    *
    * @param name      the name of an injection of a Haxel component.
    * @param className the name of a component class which a factory should built.
    * @param pos       a position of the declaration in the Haxel context config.
    * @return an expression which registers a component.
    **/
    private function buildRegisterFactoryInjectionExpr(injectionName:String, className:String, pos:Position):Expr {
        var classExpr = e(EConst(CIdent(className)), pos);
        var kindExpr = e(ECall(e(EConst(CIdent("FACTORY")), pos), [classExpr]), pos);
        var registerFunExpr = e(EField(e(EConst(CIdent("accessor")), pos), "registerInjection"), pos);
        return e(ECall(registerFunExpr, [e(EConst(CString(injectionName))), kindExpr]));
    }

    /**
    * Builds an expression which registers a instanciator of components in a scope.
    * <code>
    *  scope.registerInjection("myComponent", INSTANCE(MyComponent));
    * </code>
    *
    * @param name      the name of an injection of a Haxel component.
    * @param className the name of a component class which should be instanciate on each injection.
    * @param pos       a position of the declaration in the Haxel context config.
    * @return an expression which registers a component.
    **/
    private function buildRegisterInstanceInjectionExpr(injectionName:String, className:String, pos:Position):Expr {
        var classExpr = e(EConst(CIdent(className)), pos);
        var kindExpr = e(ECall(e(EConst(CIdent("NEW_INSTANCE")), pos), [classExpr]), pos);
        var registerFunExpr = e(EField(e(EConst(CIdent("accessor")), pos), "registerInjection"), pos);
        return e(ECall(registerFunExpr, [e(EConst(CString(injectionName))), kindExpr]));
    }
}
