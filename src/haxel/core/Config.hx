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

import Type.ValueType;

/**
* A Haxel application config.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class Config {
    /**
    * An array of contexts definitions where a scope key has no parameters.
    **/
    private var enumContexts:Array<ContextDef>;

    /**
    * An array of contexts definitions where a scope key has at least one parameters.
    **/
    private var parameterizedEnumContexts:Array<ContextDef>;

    /**
    * An array of contexts definitions where a scope key is a reference to enum constructor.
    **/
    private var functionContexts:Array<ContextDef>;

    /**
    * Constructs an instance of a config.
    **/
    public function new() {
        enumContexts = [];
        functionContexts = [];
        parameterizedEnumContexts = [];
    }

    /**
    * Registers a Haxel context by a key.
    *
    * @param scopeKey a key of a scope.
    * @param context  a context to register by a key.
    **/
    public function register(scopeKey:Null<Dynamic>, context:Class<IHaxelContext>):Void {
        var def:ContextDef = {context: context, key: scopeKey};
        switch(Type.typeof(scopeKey)) {
            case TEnum(e):
                if (Type.enumParameters(cast scopeKey).length > 0) {
                    parameterizedEnumContexts.push(def);
                } else {
                    enumContexts.push(def);
                }
            case TFunction:
                functionContexts.push(def);
            default:
                throw "Key " + scopeKey + " is not supported";
        }
    }

    /**
    * Resolves Haxel context classes by a key.
    *
    * @param scopeKey the key of a scope.
    * @return an array of Haxel context classes.
    **/
    public function getScope(scopeKey:Null<EnumValue>):Null<Array<Class<IHaxelContext>>> {
        //TODO use cache
        switch(Type.typeof(scopeKey)) {
            case TEnum(e):
                var result:Array<Class<IHaxelContext>> = [];
                if (Type.enumParameters(scopeKey).length > 0) {
                    for (def in parameterizedEnumContexts) {
                        if (Type.enumEq(def.key, scopeKey)) {
                            result.push(def.context);
                        }
                    }
                } else {
                    for (def in enumContexts) {
                        if (Type.enumEq(def.key, scopeKey)) {
                            result.push(def.context);
                        }
                    }
                }
                var functionKey = Reflect.field(e, Type.enumConstructor(scopeKey));
                switch(Type.typeof(functionKey)) {
                    case TFunction:
                        for (def in functionContexts) {
                            if (def.key == functionKey) {
                                result.push(def.context);
                            }
                        }
                    default:
                }
                return result;
            default:
                return null;
        }
        return null;
    }
}

/**
* A definition of a context.
**/
typedef ContextDef = {
    /**
    * The class of a context.
    **/
    var context:Class<IHaxelContext>;

    /**
    * The key of a scope for the context.
    **/
    var key:Dynamic;
}
