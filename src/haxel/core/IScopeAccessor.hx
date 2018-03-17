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

/**
* A enum defines a criteria of an injection search over a scope.
**/
enum HaxelInjectionCriteria {
    /**
    * Finds injection matched a key in the scope and connected scopes.
    **/
    ANY;

    /**
    * Finds injection matched a key in a filtered set of scopes by a scopeKey.
    **/
    EXACT(scopeKey:Dynamic);

    /**
    * Finds injection matched a key in a filtered set of scopes by a scopeKeys and
    * if there are no injections it tries to find an injection by ANY selector in the scope and connected scopes.
    **/
    PREFER(scopeKeys:Array<Dynamic>);
}

/**
* A enum defines the kind of an injection in a Haxel context.
**/
enum HaxelInjectionKind {
    /**
    * Defines an injection as an instance of an object.
    *
    * @param value an instance of the an object.
    **/
    VALUE(value:Null<Dynamic>);

    /**
    * Defines an injection as a refrence to another injectable by target key.
    *
    * @param target a string key of an injectable.
    **/
    //TODO implement
    REF(target:String);

    /**
    * Defines an injection as factory of components of a given type.
    *
    * @param componentClass a class name of a Haxel component.
    **/
    FACTORY(componentClass:Class<IHaxelComponent>);

    /**
    * Defines an injection as instance creator for each inject request of a component of a given type.
    *
    * @param componentClass a class name of a Haxel component.
    **/
    INSTANCE(componentClass:Class<IHaxelComponent>);
}

/**
* An interface which allows to fill and manage a scope via a configurable Haxel context.
**/
interface IScopeAccessor {
    /**
    * Gets an injection by a key from this scope.
    *
    * @param key the key of an injection.
    * @return an instance of an found injection if an injection is not found than the method returns null.
    **/
    @:noCompletion
    function getOwnInjection(key:String):Null<Dynamic>;

    /**
    * Gets an injection by a key from this scope and connected scopes.
    *
    * @param key      the key of an injection.
    * @param selector the type of an injection search.
    * @return an instance of an found injection if an injection is not found than the method returns null.
    **/
    @:noCompletion
    function getInjection(key:String, selector:HaxelInjectionCriteria):Null<Dynamic>;

    /**
    * Gets an instance of an connected scope.
    *
    * @param key the key of a scope.
    * @return the instance of a scope.
    **/
    @:noCompletion
    function getScope(key:Dynamic):IScope;

    /**
    * @return the instance of the current scope.
    **/
    @:noCompletion
    function getCurrent():IScope;

    /**
    * Adds an event handler to the scope.
    *
    * @param event   an event to listen.
    * @param handler a method which handles en event.
    **/
    @:noCompletion
    function addHandler(event:String, handler:EnumValue -> Void):Void;

    /**
    * Remove an event handler from the scope.
    *
    * @param event   an event to listen.
    * @param handler a method which handles en event.
    **/
    @:noCompletion
    function removeHandler(event:String, handler:EnumValue -> Void):Void;

    /**
    * Registers an injection into this scope.
    *
    * @param key       the key of an injection.
    * @param injection the kind of an injection.
    **/
    @:noCompletion
    function registerInjection(key:String, injection:HaxelInjectionKind):Void;
}
