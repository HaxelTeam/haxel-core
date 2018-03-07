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
package haxel.core.impl;

import haxel.core.macro.ToxicMacro;

/**
* A scope which can fill himself from contexts registered in a config by the scope key.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class Scope extends BaseScope {
    /**
    * A list of contexts which fill this scope.
    **/
    private var contexts:Array<IToxicContext>;

    /**
    * Constructs an instance of a scope.
    *
    * @param scopeKey        the key of a scope.
    * @param manager         a manager which initiates creation of this scope.
    * @param parent          a parent of a creating scope.
    * @param connectedScopes a list of connected scopes.
    **/
    public function new(scopeKey:EnumValue, manager:ScopeManagerInternal,
                        parent:Null<BaseScope>, connectedScopes:Array<IScope>) {
        super(scopeKey, manager, parent, connectedScopes);
        contexts = [];
        var cotextClasses = manager.getConfig().getScope(scopeKey);
        if (cotextClasses != null) {
            manager.lockEvents();
            processInitialization(cotextClasses);
            manager.unlockEvents();
        }
    }

    /**
    * Initialises contexts instances and process intialisation of this scope.
    **/
    private function processInitialization(cotextClasses:Array<Class<IToxicContext>>):Void {
        for (ctxClass in cotextClasses) {
            contexts.push(Type.createInstance(ctxClass, []));
        }
        for (ctx in contexts) {
            ToxicMacro.toxicCall(ctx.constructComponents(this));
        }
        for (ctx in contexts) {
            ToxicMacro.toxicCall(ctx.prepareComponents(this));
        }
        for (ctx in contexts) {
            ToxicMacro.toxicCall(ctx.initComponents(getScopeKey()));
        }
    }

    override function doRelease() {
        for (ctx in contexts) {
            ToxicMacro.toxicCall(ctx.releaseComponents());
        }
    }
}
