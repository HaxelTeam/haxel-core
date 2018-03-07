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
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;
import haxel.core.macro.HaxelHelper;
import haxel.core.macro.HaxelHelper.e;

/**
* Defines a struture which contains a map of handlers of the specific event type.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
typedef EventTypeHandlersDef = {
    /**
    * The type of an event.
    **/
    var eventType:ComplexType;

    /**
    * The declaration descriptor of an enum.
    **/
    var eventEnumDecl:EnumDeclarationDef;

    /**
    * A map of handlers by the field of an event enum.
    **/
    var typeHandlers:StringMap<EventHandlersDef>;
}

/**
* Defines a structure which contains handler expressions on an event.
**/
typedef EventHandlersDef = {
    /**
    * The case expression of a field of an event enum.
    **/
    var caseExpr:Expr;

    /**
    * The array of handler expressions where each of it handles an event.
    **/
    var handlres:Array<Expr>;
}

/**
* A code generator is used to build implementation of a Haxel component on the macro phase.
**/
class HaxelComponentCodeGen {
    /**
    * An index is used to generate unique names for handler functions.
    **/
    private static var handlerIndex:Int = 0;

    /**
    * Builds a function which attaches a component (IHaxelComponent#attach) to a scope.
    *
    * <code>
    *   function #attach(accessor: IScopeAccessor);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildAttachFun(?body:Expr):Field {
        var scopeType = HaxelHelper.tHaxel("IScopeAccessor");
        var scopeArg:FunctionArg = {value: null, type: scopeType, opt: false, name: "accessor"};
        var constructFun:Function = {ret:HaxelHelper.tVoid(), params:[], expr: body, args:[scopeArg]};
        return buildHaxelFun("attach", constructFun);
    }

    /**
    * Builds a function which initialises a component (IHaxelComponent#init).
    *
    * <code>
    *   function #init(initData: Dynamic);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildInitFun(?body:Expr):Field {
        var initDataArg:FunctionArg = {value: null, type: HaxelHelper.tDynamic(), opt: false, name: "initData"};
        var initFun:Function = {ret:HaxelHelper.tVoid(), params:[], expr: body, args:[initDataArg]};
        return buildHaxelFun("init", initFun);
    }

    /**
    * Builds a function which detaches a component (IHaxelComponent#detach) from the attached scope.
    *
    * <code>
    *   function #detach(accessor: IScopeAccessor);
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildDetachFun(?body:Expr):Field {
        var scopeType = HaxelHelper.tHaxel("IScopeAccessor");
        var scopeArg:FunctionArg = {value: null, type: scopeType, opt: false, name: "accessor"};
        var constructFun:Function = {ret:HaxelHelper.tVoid(), params:[], expr: body, args:[scopeArg]};
        return buildHaxelFun("detach", constructFun);
    }

    /**
    * Builds a function which releases a component (IHaxelComponent#release).
    *
    * <code>
    *   function #release();
    * </code>
    *
    * @param body an expression represents a body of the function.
    * @return a field definition of the function.
    **/
    public static function buildReleaseFun(?body:Expr):Field {
        var releaseFun = {ret:HaxelHelper.tVoid(), params:[], expr: body, args:[]};
        return buildHaxelFun("release", releaseFun);
    }

    /**
    * Builds a Haxel method definition.
    *
    * @param name an orginal name of the method.
    * @param fun  a method function definition.
    **/
    private static function buildHaxelFun(name:String, fun:Function):Field {
        return HaxelHelper.f(HaxelHelper.getHaxelName(name), FFun(fun));
    }

    /**
    * The body of the <code>IHaxelComponent#attach</code> function.
    **/
    private var attachBody:Array<Expr>;

    /**
    * The body of the <code>IHaxelComponent#init</code> function.
    **/
    private var initBody:Array<Expr>;

    /**
    * The body of the <code>IHaxelComponent#detach</code> function.
    **/
    private var detachBody:Array<Expr>;

    /**
    * The body of the <code>IHaxelComponent#release</code> function.
    **/
    private var releaseBody:Array<Expr>;

    /**
    * The set of event handler expression definitions grouped by event types.
    **/
    private var handlers:StringMap<EventTypeHandlersDef>;

    /**
    * Constructs an instance of the generator.
    **/
    public function new() {
        attachBody = [];
        initBody = [];
        detachBody = [];
        releaseBody = [];
        handlers = new StringMap<EventTypeHandlersDef>();
    }

    /**
    * Generates implementation of the current component in the macro Context.
    **/
    public function generate():Array<Field> {
        var fields = Context.getBuildFields();
        var overrideHaxel = isExtendsHaxel();
        if (overrideHaxel) {
            attachBody = [HaxelHelper.superHaxelCall("attach", ["accessor"])];
            initBody = [HaxelHelper.superHaxelCall("init", ["initData"])];
            detachBody = [HaxelHelper.superHaxelCall("detach", ["accessor"])];
            releaseBody = [HaxelHelper.superHaxelCall("release", [])];
        }
        for (field in fields) {
            for (metadata in field.meta) {
                switch(metadata.name) {
                    case ":Inject":
                        var scopeSelector:Expr = e(EConst(CIdent("ANY")));
                        var name:String = field.name;
                        for (injectParam in metadata.params) {
                            var paramDef:ExprDef = injectParam.expr;
                            switch(paramDef) {
                                case ExprDef.EBinop(Binop.OpAssign, e1, e2):
                                    switch(e1.expr) {
                                        case ExprDef.EConst(CIdent("scope")):
                                            scopeSelector = e(ExprDef.ECall(e(EConst(CIdent("EXACT"))), [e2]));
                                        case ExprDef.EConst(CIdent("name")):
                                            switch(e2.expr) {
                                                case ExprDef.EConst(CIdent(nameValue)):
                                                    name = nameValue;
                                                case ExprDef.EConst(CString(nameValue)):
                                                    name = nameValue;
                                                default:
                                            }
                                        case ExprDef.EConst(CIdent("scopes")):
                                            scopeSelector = e(ExprDef.ECall(e(EConst(CIdent("PREFER"))), [e2]));
                                        default:
                                    }
                                default:
                            }
                        }
                        attachBody.push(buildInjectBody(field, name, scopeSelector));
                    case ":Scope":
                        if (metadata.params.length > 0) {
                            attachBody.push(buildScopeBody(field, metadata.params[0]));
                        } else {
                            attachBody.push(buildCurrentScopeBody(field));
                        }
                    case ":Release":
                        releaseBody.push(buildSimpleCall(field));
                    case ":Init":
                        if (metadata.params.length > 0) {
                            for (metaParam in metadata.params) {
                                var enumDecl = HaxelHelper.getEnumDecl(metaParam);
                                if (enumDecl != null) {
                                    initBody.push(buildInitBody(field, enumDecl));
                                } else {
                                    Errors.invalidInitParam(field.pos);
                                }
                            }
                        } else {
                            switch(field.kind) {
                                case FFun(fun):
                                    if (fun.args.length > 1) {
                                        Errors.invalidInitParam(field.pos);
                                    } else {
                                        initBody.push(buildDynamicInitBody(field, fun));
                                    }
                                default:
                                    Errors.invalidInitParam(field.pos);
                            }
                        }
                    case ":Handle":
                        for (metaParam in metadata.params) {
                            var enumDecl = HaxelHelper.getEnumDecl(metaParam);
                            if (enumDecl != null) {
                                var fullEnumName = TypeTools.toString(TEnum(enumDecl.type, []));
                                var handlersOfType = handlers.get(fullEnumName);
                                if (handlersOfType == null) {
                                    handlersOfType = {
                                        typeHandlers: new StringMap<EventHandlersDef>(),
                                        eventType: Context.toComplexType(TEnum(enumDecl.type, [])),
                                        eventEnumDecl: enumDecl
                                    };
                                    handlers.set(fullEnumName, handlersOfType);
                                }
                                var eventHandlerDef = handlersOfType.typeHandlers.get(enumDecl.field);
                                if (eventHandlerDef == null) {
                                    eventHandlerDef = {
                                        caseExpr: buildEnumCaseMatcher(enumDecl),
                                        handlres: []
                                    };
                                    handlersOfType.typeHandlers.set(enumDecl.field, eventHandlerDef);
                                }
                                eventHandlerDef.handlres.push(buildHandlerBody(field, enumDecl));
                            } else {
                                Errors.invalidHandlerForm(metadata.pos);
                            }
                        }
                    default:
                }
            }
        }
        var handlers = generateHandlerFields();
        var haxelFields = [
            buildAttachFun(e(EBlock(attachBody))),
            buildInitFun(e(EBlock(initBody))),
            buildDetachFun(e(EBlock(detachBody))),
            buildReleaseFun(e(EBlock(releaseBody)))
        ];
        if (overrideHaxel) {
            for (haxelField in haxelFields) {
                haxelField.access.push(AOverride);
            }
        }
        return fields.concat(handlers).concat(haxelFields);
    }

    /**
    * Check whether is the generated class already extends an Haxel component.
    **/
    private function isExtendsHaxel():Bool {
        var classRef = Context.getLocalClass();
        var iHaxelType = ComplexTypeTools.toType(HaxelHelper.tHaxel("IHaxelComponent"));
        return HaxelHelper.getGeneration(classRef, iHaxelType) > 0;
    }

    /**
    * Generates bodies for event handlers. Registers it on #prepare of current component.
    **/
    private function generateHandlerFields():Array<Field> {
        var handlerFields:Array<Field> = [];
        for (enumTypeName in handlers.keys()) {
            var handlersOfType = handlers.get(enumTypeName);
            var eventNames:Array<String> = [];
            var eventCases:Array<Case> = [];
            for (enumFieldName in handlersOfType.typeHandlers.keys()) {
                eventNames.push(enumTypeName + ":" + enumFieldName);
                var handlersDef = handlersOfType.typeHandlers.get(enumFieldName);
                eventCases.push({
                    values: [handlersDef.caseExpr],
                    expr: e(EBlock(handlersDef.handlres))});
            }
            var eventTypeCastExpr = e(ECast(e(EConst(CIdent("event"))), handlersOfType.eventType));
            var defaultExpr = null;
            if (eventCases.length < handlersOfType.eventEnumDecl.type.get().names.length) {
                defaultExpr = e(EThrow(e(EConst(CString(Errors.NO_HANDLERS_FOUND_FOR_EVENT)))));
            }
            var handlerBody = e(ESwitch(eventTypeCastExpr, eventCases, defaultExpr));
            var handlerWrapper = buildHandlerWrapper(handlerBody);
            handlerFields.push(handlerWrapper);
            for (eventName in eventNames) {
                attachBody.push(buildAddHandlerBody(eventName, handlerWrapper.name));
                detachBody.push(buildRemoveHandlerBody(eventName, handlerWrapper.name));
            }
        }
        return handlerFields;
    }

    /**
    * Builds type safe function wrappers for event handling
    *
    * <code>
    *   function #h123(event: EnumValue):Void {
    *       switch(cast(event, Turn)) {
    *           case PLAYER_TURN(player, score):
    *               call actual handlres here...
    *           case COMPUTER_TURN:
    *               call actual handlres here...
    *       }
    *   }
    * </code>
    **/
    private function buildHandlerWrapper(body:Expr):Field {
        var eventArg:FunctionArg = {value: null, type: HaxelHelper.tEnumValue(), opt: false, name: "event"};
        var initFun:Function = {ret:HaxelHelper.tVoid(), params:[], expr: body, args:[eventArg]};
        handlerIndex++;
        return buildHaxelFun("h" + handlerIndex, initFun);
    }

    /**
    * Builds a body part of <code>IHaxelComponent#attach</code> function to register a handler.
    * <code>
    *    accessor.addHandler("events.Turn:PLAYER_TURN", this.handler123);
    * </code>
    *
    * @param eventName   the full name of an event.
    * @param handlerName the name of a function which handles an event.
    * @return an expression which registers an event handler to a scope.
    **/
    private function buildAddHandlerBody(eventName:String, handlerName:String):Expr {
        var addHandlerExpr = e(EField(e(EConst(CIdent("accessor"))), "addHandler"));
        var handlerWrapperExpr = e(EField(e(EConst(CIdent("this"))), handlerName));
        var eventNameExpr = e(EConst(CString(eventName)));
        return e(ECall(addHandlerExpr, [eventNameExpr, handlerWrapperExpr]));
    }

    /**
    * Builds a body part of <code>IHaxelComponent#detach</code> function to remove a handler.
    * <code>
    *    accessor.removeHandler("events.Turn:PLAYER_TURN", this.handler123);
    * </code>
    *
    * @param eventName   the full name of an event.
    * @param handlerName the name of a function which handles an event.
    * @return an expression which removes an event handler from a scope.
    **/
    private function buildRemoveHandlerBody(eventName:String, handlerName:String):Expr {
        var addHandlerExpr = e(EField(e(EConst(CIdent("accessor"))), "removeHandler"));
        var handlerWrapperExpr = e(EField(e(EConst(CIdent("this"))), handlerName));
        var eventNameExpr = e(EConst(CString(eventName)));
        return e(ECall(addHandlerExpr, [eventNameExpr, handlerWrapperExpr]));
    }

    /**
    * Builds a body part of <code>IHaxelComponent#attach</code> function to initialize an injection.
    * <code>
    *     this.dependency = accessor.getInjection("dependency", ANY);
    * </code>
    *
    * @param field         a field keeps an instance of the injection dependency.
    * @param name          a key name of the injection dependency.
    * @param scopeSelector a key name of the injection dependency.
    * @return an expression which initializes the dependency.
    **/
    private function buildInjectBody(field:Field, name:String, scopeSelector:Null<Expr>):Expr {
        var field = e(EField(e(EConst(CIdent("this"))), field.name));
        var getInjection = e(EField(e(EConst(CIdent("accessor"))), "getInjection"));
        var getFromScope = e(ECall(getInjection, [e(EConst(CString(name))), scopeSelector]));
        return e(EBinop(Binop.OpAssign, field, getFromScope));
    }

    /**
    * Builds a body part of <code>IHaxelComponent#attach</code> function
    * to initialize a current scope dependency.
    *
    * <code>
    *     this.scope = accessor.getCurrent();
    * </code>
    *
    * @param field a field keeps an instance of the current scope.
    * @return an expression which initializes the current scope.
    **/
    private function buildCurrentScopeBody(field:Field):Expr {
        var field = e(EField(e(EConst(CIdent("this"))), field.name));
        var getCurrent = e(EField(e(EConst(CIdent("accessor"))), "getCurrent"));
        return e(EBinop(Binop.OpAssign, field, e(ECall(getCurrent, []))));
    }

    /**
    * Builds a body part of <code>IHaxelComponent#attach</code> function
    * to initialize a connected scope dependency.
    *
    * <code>
    *     this.playerScope = accessor.getScope(MyScope.PLAYER);
    * </code>
    *
    * @param field    a field keeps a scope instance.
    * @param scopeKey a key of the connected scope.
    * @return an expression which initializes a connected scope.
    **/
    private function buildScopeBody(field:Field, scopeKey:Expr):Expr {
        var field = e(EField(e(EConst(CIdent("this"))), field.name));
        var getScope = e(EField(e(EConst(CIdent("accessor"))), "getScope"));
        return e(EBinop(Binop.OpAssign, field, e(ECall(getScope, [scopeKey]))));
    }

    /**
    * Builds a body part of <code>IHaxelComponent#init</code> function
    * to initialize a component with a scope key.
    *
    * <code>
    *     switch(cast (initData, AppScope)) {
    *       case MAIN(data1, data2):
    *         this.postConstruct(data1, data2);
    *       default:
    *         throw "Invalid scope type";
    *     }
    * </code>
    *
    * @param field    a field represents an initilize function of the component.
    * @param enumDecl an enum declaration descriptor definition.
    * @return an expression which run an initilizer of a Haxel component.
    **/
    private function buildInitBody(field:Field, enumDecl:EnumDeclarationDef):Expr {
        var enumType = enumDecl.type.get();
        var scopeKeyPath = Context.toComplexType(TEnum(enumDecl.type, []));
        var scopeKeyCastExpr = e(ECast(e(EConst(CIdent("initData"))), scopeKeyPath));
        var enumMatchExpr = e(EConst(CIdent(enumDecl.field)));
        var params = buildEnumParamsIdentifiers(enumDecl);
        if (params != null) {
            enumMatchExpr = e(ECall(enumMatchExpr, params));
        }
        var defaultExpr = null;
        if (enumType.names.length > 1) {
            defaultExpr = e(EThrow(e(EConst(CString(Errors.INVALID_SCOPE_INIT)))));
        }
        return e(ExprDef.ESwitch(
            scopeKeyCastExpr,
            [{values:[enumMatchExpr], expr:buildSimpleCall(field, params)}],
            defaultExpr
        ));
    }

    /**
    * Builds a body part of <code>IHaxelComponent#init</code> function
    * to initialize a component with a dynamic data.
    *
    * <code>
    *     this.postConstruct(cast initData);
    * </code>
    *
    * @param field    a field represents an initilize function of the component.
    * @param funDecl  a function declaration to be called.
    * @return an expression which run an initilizer of a Haxel component.
    **/
    private function buildDynamicInitBody(field:Field, funDecl:Function):Expr {
        var params:Array<Expr> = null;
        if (funDecl.args.length == 1) {
            var arg = funDecl.args[0];
            params = [e(ECast(e(EConst(CIdent("initData")), field.pos), null), field.pos)];
        }
        return buildSimpleCall(field, params);
    }

    /**
    * Builds a body part of <code>IHaxelComponent#handle</code> function
    * to initialize a component.
    *
    * <code>
    *    this.onTitleChange(newTitle, oldTitle);
    * </code>
    *
    * @param field    a field a handler function of the component.
    * @param enumDecl an enum declaration descriptor definition.
    * @return an expression which call handler with corresponed data from an event.
    **/
    private function buildHandlerBody(field:Field, enumDecl:EnumDeclarationDef):Expr {
        var identifiers = buildEnumParamsIdentifiers(enumDecl);
        return buildSimpleCall(field, identifiers);
    }

    /**
    * Builds an array of constant identifiers which represents paramters of an enum constructor.
    *
    * @param enumDecl an enum declaration descriptor definition.
    * @return an array of constant identifier expressions.
    **/
    private function buildEnumParamsIdentifiers(enumDecl:EnumDeclarationDef):Array<Expr> {
        var enumField = enumDecl.type.get().constructs.get(enumDecl.field);
        switch(enumField.type) {
            case TFun(args, _):
                var params:Array<Expr> = [];
                for (arg in args) {
                    params.push(e(EConst(CIdent(arg.name))));
                }
                return params;
            default:
        }
        return null;
    }

    /**
    * Builds a part of a case statement expression which handles an enum match in a switch statement.
    *
    * <code>
    *   TITLE_CHANGED(newTitle, oldTitle)
    * </code>
    *
    * @return an expression in case statement.
    **/
    private function buildEnumCaseMatcher(enumDecl:EnumDeclarationDef):Expr {
        var enumFieldNameExpr = e(EConst(CIdent(enumDecl.field)));
        var params = buildEnumParamsIdentifiers(enumDecl);
        if (params != null) {
            return e(ECall(enumFieldNameExpr, params));
        }
        return enumFieldNameExpr;
    }

    /**
    * Builds an expression which calls a field assuming that is a function.
    *
    * <code>
    *     this.fun(param1, param2, ..);
    * </code>
    *
    * @param field  a function of the component.
    * @param params an optional array of the function paramters.
    * @return an expression which calls a release function.
    **/
    private function buildSimpleCall(field:Field, ?params:Array<Expr>):Expr {
        if (params == null) {
            params = [];
        }
        var fieldExpr = e(EField(e(EConst(CIdent("this")), field.pos), field.name), field.pos);
        return e(ECall(fieldExpr, params), field.pos);
    }
}
