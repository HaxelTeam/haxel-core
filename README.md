# Haxel a Haxe event-based framework.

Haxel is a Haxe library for composing asynchronous and event-based applications.
It also includes a dependency injection.

## Getting started

Basically the Haxel allows you to setup communication between application components.
The Haxel promotes a safe strong typing event handling mechanism. Therefor first step is to
declare an event using enums:

```haxe
enum MyEvent {
    WORLD_MESSAGE(message: String);
}
```

The second step is to write a consumer for this event:

```haxe
class HelloWorldPrinter implements IHaxelComponent {

    @:Handle(MyEvent.WORLD_MESSAGE)
    public function handleWorldMessage(message: String): Void {
        trace("Hello world! " + message);
    }
}
```

To setup communication in Haxel you have to create a configuration context.

```haxe
@:Config(HelloWorldPrinter)
class HelloConfiguration implements IHaxelContext {}
```

and than you should define a configuration key for this context. 

```haxe
enum MyScope {
    ROOT;
}
```

Now you are able to create an application.
```haxe
class MyApplication {

    static function main() {
        //create config for this application
        var cfg = new Config();
        //register a configuration context in this application.
        cfg.register(MyScope.ROOT, HelloConfiguration);
        //create a manger which manages the event bus and the rest.
        //you do not care about the rest in "Hello World" applications, isn't it?
        var scopeManager = new ScopeManager(cfg);
        //all Haxel components lives in a scope and you should create one.
        var scope = scopeManager.createScope(MyScope.ROOT);
        //send a message to the scope.
        scope.send(MyEvent.WORLD_MESSAGE("Haxe is awesome!"))
    }
}
```

When you run this application it should trace:
 "Hello world! Haxe is awesome!"

## Dependency Injections

You do not want to use "trace" method to print out the world message.
You do not know what you can use for that.
You want to use an abstraction with dummy implementation which uses "trace" method.
Ok, lets do it via IoC.

At first you should declare an abstraction with an implementation.

```haxe
class IMessagePrinter {

    function print(message: String): Void
}


class DummyMessagePrinter implements IMessagePrinter {

    function print(message: String): Void {
        trace(message);
    }
}
```

Then you should register that into the "Configuration":

```haxe
@:Config(
    HelloWorldPrinter,
    {messagePrinter: DummyMessagePrinter}
)
class HelloConfiguration implements IHaxelContext {}
```

Now you should change "HelloWorldPrinter" to use that abstraction:


```haxe
class HelloWorldPrinter implements IHaxelComponent {

    @:Inject
    private var messagePrinter: IMessagePrinter;

    @:Handle(MyEvent.WORLD_MESSAGE)
    public function handleWorldMessage(message: String): Void {
        messagePrinter.print("Hello world! " + message);
    }
}
```

When you run the application now it should trace:
 "Hello world! Haxe is awesome!"
Nothing is changed but I hope you feel better.

## Scopes and Contexts

You built a "Hello world" application but it is not needed by the world.
The world needs something more. The world wants to create and to destroy.
Just imagine that you have a widget with buttons: "create", "destroy" and "send message".
So you have two click listeners.

```haxe
class DreamsWidget {

    function onCreateClick() {

    }

    function onDestroyClick() {

    }

    function onSendMessageClick() {

    }
}

```
Lets make it Haxel. But before you should define a scope key for existing HelloConfiguration.

```haxe
enum MyScope {
    HELLO;
}
```
and register this configuration with this key:

```haxe
    //register a configuration context in this application.
    cfg.register(MyScope.HELLO, HelloConfiguration);
```

Now you should define and register a DreamConfiguration:

```haxe
@:Config(DreamsWidget)
class DreamConfiguration implements IHaxelContext {}
```
and also define a configuration key for that:

```haxe
enum MyScope {
    HELLO;
    DREAM;
}
```
and register it in the root:
```haxe
   ///...
   cfg.register(MyScope.DREAM, DreamConfiguration);
```

Then you should do the standard Haxel magic:

```haxe
class DreamsWidget implements IHaxelComponent {

    //The Haxel injects a scope where the widget is appears (a root scope in our case)
    @:Scope
    private var scope: IScope;

    //Just a array of a HELLO scopes.
    private var helloScopes: Array<IScope>;

    function onCreateClick() {
        //create HELLO scope as child to current (root)
        helloScopes.push(scope.createChild(MyScope.HELLO));
    }

    function onDestroyClick() {
        var hello = helloScopes.pop();
        if (hello != null) {
            //destroy a scope
            hello.release();
        }
    }

    function onSendMessageClick() {
        //send a message to current scope. it also notifies all childrens.
        //You just should move this code here from MyApplication.
        scope.send(MyEvent.WORLD_MESSAGE("Haxe is awesome!"));
    }
}

```

Great! When you click on the "send message" button it prints nothing.
And when you click the "create" button N times and then again button "send message"
the awesome message should appeared N times.
When you click "destroy" button the "send message" button causes printing the awesome message N-1 times.

You can see that a new DummyMessagePrinter is created on each "create" button click.
But you do not want to do it. You want DummyMessagePrinter to be a singleton.
Lets do such optimisation. You should just move DummyMessagePrinter component
from HelloConfiguration to DreamConfiguration.

```haxe
@:Config(
    DreamsWidget,
    {messagePrinter: DummyMessagePrinter}
)
class DreamConfiguration implements IHaxelContext {}
```
Done.
A child HELLO scope searches all dependencies till the most parent scope and injects them to consumers.

## Advanced Haxel

//TODO links

