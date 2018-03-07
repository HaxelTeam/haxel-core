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
* A factory produces a list of components.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class ComponentToxicFactory<T : IToxicComponent> implements IToxicFactory<T> {
    /**
    * A list of componentes produces by this factory.
    **/
    private var components:List<T>;

    /**
    * An accessor interface of a scope with which this factory is connected.
    **/
    private var scopeAccessor:IScopeAccessor;

    /**
    * A class of a Toxic component to build.
    **/
    private var componentClass:Class<T>;

    /**
    * Constructs an instance.
    *
    * @param scopeAccessor  an accessor interface of a scope.
    * @param componentClass a class of a component.
    **/
    public function new(scopeAccessor:IScopeAccessor, componentClass:Class<T>) {
        this.scopeAccessor = scopeAccessor;
        this.componentClass = componentClass;
        this.components = new List<T>();
    }

//-----------------------------------------------------------
// {@link IToxicFactory} implemeteaion
//-----------------------------------------------------------
    public function create():T {
        var result:T = Type.createInstance(componentClass, []);
        ToxicMacro.toxicCall(result.attach(scopeAccessor));
        ToxicMacro.toxicCall(result.init(scopeAccessor.getCurrent().getScopeKey()));
        components.add(result);
        return result;
    }

    public function iterator():Iterator<T> {
        return components.iterator();
    }

    public function size():Int {
        return components.length;
    }

    public function release(component:T):Void {
        if (components.remove(component)) {
            ToxicMacro.toxicCall(component.detach(scopeAccessor));
            ToxicMacro.toxicCall(component.release());
        }
    }

    public function releaseAll():Void {
        for (component in components) {
            ToxicMacro.toxicCall(component.detach(scopeAccessor));
            ToxicMacro.toxicCall(component.release());
        }
        components.clear();
    }
//-----------------------------------------------------------
}
