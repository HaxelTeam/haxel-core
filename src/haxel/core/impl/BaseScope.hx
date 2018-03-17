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

import haxel.core.IScopeAccessor;

/**
* A basic implementation of a scope.
*
* @author Dmitry Razumovskiy <razumovskiy@gmail.com>
**/
class BaseScope implements IScope implements IScopeAccessor {
    /**
    * A manager of this scope.
    **/
    private var manager:ScopeManagerInternal;

    /**
    * A list of child scopes of this scope.
    **/
    private var childs:Array<BaseScope>;

    /**
    * A map of event handlers registered in this scope.
    **/
    private var handlers:Map<String, Array<EnumValue -> Void>>;

    /**
    * A flag indicates that this scope was released.
    **/
    private var released:Bool;

    /**
    * A parent of this scope.
    **/
    private var parent:Null<BaseScope>;

    /**
    * A list of scopes which are listening events of this scope.
    **/
    private var listeners:Array<BaseScope>;

    /**
    * A list of scopes on which this scope is subscribed to listen theirs events.
    **/
    private var subscribtions:Array<BaseScope>;

    /**
    * A list of notes which are waiting while a current note is processing.
    **/
    private var delayedNotes:Array<ScopeTimeOut>;

    /**
    * A key of this scope.
    **/
    private var scopeKey:EnumValue;

    /**
    * A list of connected scopes in which this scope searches injections.
    **/
    private var connectedScopes:Array<IScope>;

    /**
    * A map of injections registered in this scope.
    **/
    private var injections:Map<String, HaxelInjectionKind>;

    /**
    * A list of Haxel factories instanciated by this scope.
    **/
    private var factories:Array<IHaxelFactory<IHaxelComponent>>;

    /**
    * Constructs an instance of a base scope.
    *
    * @param scopeKey        the key of a scope.
    * @param manager         a manager which initiates creation of this scope.
    * @param parent          a parent of a creating scope.
    * @param connectedScopes a list of connected scopes.
    **/
    public function new(scopeKey:EnumValue, manager:ScopeManagerInternal,
                        parent:BaseScope, connectedScopes:Array<IScope>) {
        this.scopeKey = scopeKey;
        this.manager = manager;
        this.parent = parent;
        this.connectedScopes = (connectedScopes == null) ? [] : connectedScopes;
        released = false;
        handlers = new Map<String, Array<EnumValue -> Void>>();
        childs = [];
        listeners = [];
        subscribtions = [];
        delayedNotes = [];
        injections = new Map<String, HaxelInjectionKind>();
        factories = [];
        if (parent != null) {
            parent.childs.push(this);
        }
    }

    /**
    * Checks is an scope is a parent of this scope.
    *
    * @param scope a scope is a candidate for a parent.
    **/
    private function hasHeritage(scope:BaseScope):Bool {
        var prt:Null<BaseScope> = this;
        while ((prt != null) && (prt != scope)) {
            prt = prt.parent;
        }
        return prt == scope;
    }

    /**
    * Checks equality of two scope keys.
    *
    * @param scopeKey a key of a scope.
    * @param key      a key of another scope.
    **/
    private function isScopeKeysEquals(scopeKey:EnumValue, key:Dynamic):Bool {
        var scopeEnum:Enum<Dynamic> = Type.getEnum(scopeKey);
        switch(Type.typeof(key)) {
            case TEnum(e):
                return Type.enumEq(scopeKey, key);
            case TFunction:
                return Reflect.field(scopeEnum, Type.enumConstructor(scopeKey)) == key;
            default:
                return false;
        }
    }

    /**
    * Finds a scope by a key over connected scopes including parent's connected scopes.
    *
    * @param scopeKey the key of a scope to search by.
    * @return a found scope.
    **/
    function findConnected(scopeKey:Dynamic):BaseScope {
        for (connected in this.connectedScopes) {
            if (isScopeKeysEquals(connected.getScopeKey(), scopeKey)) {
                return cast connected;
            }
        }
        if (parent != null) {
            return parent.findConnected(scopeKey);
        }
        return null;
    }

    /**
    * Finds an injection by a key registered in this scope.
    *
    * @param key       the key of an injection.
    * @param requester a scope which requests an injection search.
    * @return a found injection or null if there is no an injection with specified key.
    **/
    public function getOwnInjectionForRequester(key:String, requester:BaseScope):Null<Dynamic> {
        if (injections.exists(key)) {
            return switch(injections.get(key)) {
                case REF(target):
                    getInjection(target, ANY);
                case VALUE(value):
                    value;
                case FACTORY(componentClass):
                    var factory = new ComponentHaxelFactory(this, componentClass);
                    requester.factories.push(factory);
                    factory;
                case INSTANCE(componentClass):
                    var factory = new ComponentHaxelFactory(this, componentClass);
                    requester.factories.push(factory);
                    factory.create();
            }
        }
        return null;
    }

    /**
    * Finds an injection by a key registered in this scope.
    *
    * @param key       the key of an injection.
    * @param criteria  a criteria to search an injection by.
    * @param requester a scope which requests an injection search.
    * @return a found injection or throws an exeption if there is no an injection with specified key.
    **/
    public function getInjectionForRequester(key:String, criteria:HaxelInjectionCriteria, requester:BaseScope):Null<Dynamic> {
        switch(criteria) {
            case ANY:
                var result = getOwnInjectionForRequester(key, requester);
                if (result != null) {
                    return result;
                }
                for (connected in this.connectedScopes) {
                    var connectedAccessor:BaseScope = cast connected;
                    result = connectedAccessor.getOwnInjectionForRequester(key, requester);
                    if (result != null) {
                        return result;
                    }
                }
                if (parent != null) {
                    return parent.getInjectionForRequester(key, ANY, requester);
                }
            case EXACT(scopeKey):
                if (isScopeKeysEquals(this.scopeKey, scopeKey)) {
                    var result = getOwnInjectionForRequester(key, requester);
                    if (result != null) {
                        return result;
                    }
                } else {
                    var connectedScope = findConnected(scopeKey);
                    if (connectedScope != null) {
                        var result = connectedScope.getOwnInjectionForRequester(key, requester);
                        if (result != null) {
                            return result;
                        }
                    } else if (parent != null) {
                        return parent.getInjectionForRequester(key, criteria, requester);
                    }
                }
            case PREFER(scopeKeys):
                //TODO cache it
                var includes:Array<BaseScope> = [];
                for (scopeKey in scopeKeys) {
                    if (isScopeKeysEquals(this.scopeKey, scopeKey)) {
                        includes.push(this);
                    }
                    var connectedScope = findConnected(scopeKey);
                    if (connectedScope != null) {
                        includes.push(connectedScope);
                    }
                }
                for (include in includes) {
                    var result = include.getOwnInjectionForRequester(key, requester);
                    if (result != null) {
                        return result;
                    }
                }
                return getInjectionForRequester(key, ANY, requester);
        }
        throw "Injection \"" + key + "\" requested by " + requester.getScopeKey() + " did not found";
    }

    /**
    * Returns the key name of an scope.
    *
    * @param enumKey the key of a scope.
    * @returns a key name.
    **/
    //TODO use build type relative Hash
    private function getKeyName(enumKey:EnumValue):String {
        return Utils.getEnumName(enumKey);
    }

    /**
    * Notifies all observers of an event by a note.
    *
    * @param note a note to send to observers.
    **/
    private function notifyObservers(note:EnumValue):Void {
        var eventHandlers = handlers.get(getKeyName(note));
        if (eventHandlers != null) {
            for (h in eventHandlers) {
                Log.debug("Send note " + Type.getEnumName(Type.getEnum(note)) + "." + Std.string(note) + " to " + getScopeKey());
                h(note);
            }
        }
        //TODO introduce "event ways".
        for (c in childs) {
            c.send(note);
        }
    }

    /**
    * Sends the note from a scope timeout.
    *
    * @param timeout a timeout contains a note to send.
    **/
    public function processTimeout(timeout:ScopeTimeOut):Void {
        this.delayedNotes.remove(timeout);
        send(timeout.note);
    }

    /**
    * Cancels a scope timeout.
    *
    * @param timeout a scope timeout of this scope.
    **/
    public function cancelTimeout(timeout:ScopeTimeOut):Void {
        this.delayedNotes.remove(timeout);
    }

    /**
    * A function is called when actual release process is performed.
    **/
    function doRelease():Void {}
//-----------------------------------------------------------------------------
//  {@link IScopeAccessor} implementation
//-----------------------------------------------------------------------------
    public function getOwnInjection(key:String):Null<Dynamic> {
        return getOwnInjectionForRequester(key, this);
    }

    public function getInjection(key:String, selector:HaxelInjectionCriteria):Null<Dynamic> {
        return getInjectionForRequester(key, selector, this);
    }

    public function getScope(key:Dynamic):IScope {
        if (isScopeKeysEquals(this.scopeKey, key)) {
            return this;
        }
        for (connected in this.connectedScopes) {
            var connectedScope:BaseScope = cast connected;
            if (isScopeKeysEquals(connectedScope.scopeKey, key)) {
                return connected;
            }
        }
        if (parent != null) {
            if (isScopeKeysEquals(parent.scopeKey, key)) {
                return parent;
            } else {
                return parent.getScope(key);
            }
        }
        throw "BaseScope \"" + key + "\" not found";
    }

    public function getCurrent():IScope {
        return this;
    }

    public function addHandler(event:String, handler:EnumValue -> Void):Void {
        var oldHandlers = handlers.get(event);
        if (oldHandlers != null) {
            oldHandlers.push(handler);
        } else {
            handlers.set(event, [handler]);
        }
    }

    public function removeHandler(event:String, handler:EnumValue -> Void):Void {
        var oldHandlers = handlers.get(event);
        if (oldHandlers != null) {
            oldHandlers.remove(handler);
        }
    }

    public function registerInjection(name:String, injection:HaxelInjectionKind):Void {
        injections.set(name, injection);
    }
//-----------------------------------------------------------------------------
//  {@link IScope} implementation
//-----------------------------------------------------------------------------
    public function send(note:EnumValue):Void {
        if (released) {
            return;
        }
        if (manager.isLocked()) {
            manager.delayNote(this, note);
        } else {
            manager.lockEvents();
            try {
                notifyObservers(note);
                for (listener in listeners) {
                    listener.notifyObservers(note);
                }
            } catch (e:Dynamic) {
                Log.error("Error when notify observers with note " + Std.string(note));
                manager.unlockEvents();
                throw e;
            }
            manager.unlockEvents();
        }
    }

    public function sendAfter(note:Dynamic, timeout:Int = 0):Null<IScopeTimeOut> {
        if (released) {
            return null;
        }
        if (timeout <= 0) {
            send(note);
            return null;
        }
        var result = new ScopeTimeOut(timeout, this, note);
        delayedNotes.push(result);
        return result;
    }

    public function createChild(scopeKey:EnumValue, connectedScopes:Array<IScope> = null):IScope {
        if (released) {
            return null;
        }
        return new Scope(scopeKey, manager, this, connectedScopes);
    }

    public function subscribe(scope:IScope):Void {
        var haxelScope:BaseScope = cast scope;
        if (!released
        && !haxelScope.released
        && !hasHeritage(haxelScope)
        && !Lambda.has(subscribtions, haxelScope)) {
            haxelScope.listeners.push(this);
            subscribtions.push(haxelScope);
        }
    }

    public function unsubscribe(scope:IScope):Void {
        var haxelScope:BaseScope = cast scope;
        subscribtions.remove(haxelScope);
        haxelScope.listeners.remove(this);
    }

    public function release():Void {
        if (!released) {
            if (manager.isLocked()) {
                manager.delayRelease(this);
            } else {
                if (parent != null) {
                    parent.childs.remove(this);
                }
                released = true;
                var oldChildrens = childs;
                childs = [];
                for (c in oldChildrens) {
                    c.release();
                }
                for (scope in subscribtions) {
                    scope.listeners.remove(this);
                }
                for (scope in listeners) {
                    scope.subscribtions.remove(this);
                }
                doRelease();
                for (factory in factories) {
                    factory.releaseAll();
                }
            }
        }
    }

    public function removeChild(child:IScope):Void {
        var scopeChild:BaseScope = cast child;
        if (scopeChild.parent == this) {
            scopeChild.release();
        }
    }

    public function getScopeKey():EnumValue {
        return scopeKey;
    }

    public function isReleased():Bool {
        return released;
    }
//-----------------------------------------------------------------------------
}