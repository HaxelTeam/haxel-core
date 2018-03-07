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

import haxe.PosInfos;
import haxe.macro.Expr;

/*
 * The enum of available log levels 
 */
enum LogLevel {
    FATAL;
    ERROR;
    WARN;
    INFO;
    DEBUG;
}

/*
 * The set of useful methods and macros to log information. Each macro prevents from
 * redundant calculations, for example code:
 *
 *    Log.debug("Statistic for this time is: " + calculateAndAggregateStatisticToString());
 * 
 * will be expanded to:
 *
 *    if(Log.isLevelAllowed(DEBUG)) {
 *        Log.log(DEBUG, "Statistic for this time is: " + calculateAndAggregateStatisticToString());
 *    }
 * 
 * So, log level will be checked before method "calculateAndAggregateStatisticToString" calls.
 */
class Log {

    private static var classLogLevelMap:Map<String, LogLevel> = new Map<String, LogLevel>();

    private static var defaultLogLevel:LogLevel = ERROR;

    /*
	 * Sets default log level
	 */
    public static function setDefault(level:LogLevel):Void {
        defaultLogLevel = level;
    }

    /*
	 * Sets log level for a Class
	 */
    public static function setClassLogLevel(c:Class<Dynamic>, level:LogLevel):Void {
        setLogLevel(Type.getClassName(c), level);
    }

    /*
	 * Sets log level for a Class by class name
	 */
    public static function setLogLevel(className:String, level:LogLevel):Void {
        classLogLevelMap.set(className, level);
    }

    /*
	 * Checks log level in current position
	 */
    public static function isLevelAllowed(value:LogLevel, ?pos:PosInfos):Bool {
        var logLevel = classLogLevelMap.get(pos.className);
        if (logLevel == null) {
            logLevel = defaultLogLevel;
        }
        return switch(logLevel) {
            case LogLevel.FATAL:
                switch(value) {
                    case LogLevel.FATAL:
                        true;
                    default:
                        false;
                }
            case LogLevel.ERROR:
                switch(value) {
                    case LogLevel.FATAL, ERROR:
                        true;
                    default:
                        false;
                }
            case LogLevel.WARN:
                switch(value) {
                    case LogLevel.FATAL, ERROR, WARN:
                        true;
                    default:
                        false;
                }
            case LogLevel.INFO:
                switch(value) {
                    case LogLevel.FATAL, ERROR, WARN, INFO:
                        true;
                    default:
                        false;
                }
            case LogLevel.DEBUG:
                true;
        }
    }

    /*
	 * Write log message with specified log level 
	 */
    public static function log(level:LogLevel, msg:Dynamic, ?pos:PosInfos):Void {
        var message = "[" + level + "]\t" + Date.now() + "\t" + pos.fileName + "[" + pos.lineNumber + "]: " + Std.string(msg);
#if (flash9 || flash10)
        untyped __global__["trace"](message);
#elseif flash
        flash.Lib.trace(message);
#else
        haxe.Log.trace(message);
#end
    }

#if macro

    private static function logMacro(level:LogLevel, message:Expr):Expr {
        var logLevel = {expr: EConst(CIdent(Std.string(level))), pos: message.pos};
        var logClass = {expr : EConst(CIdent("Log")), pos: message.pos};
        var funTrace = {expr: EField(logClass, "log"), pos: message.pos};
        var traceCall = {expr : ECall(funTrace, [logLevel, message]), pos: message.pos};
        var allowedFun = {expr: EField(logClass, "isLevelAllowed"), pos: message.pos};
        var econd = {expr: ECall(allowedFun, [logLevel]), pos: message.pos};
        return {expr : EIf(econd, traceCall, null), pos: message.pos};
    }
#end

    /*
	 * Generates DEBUG log level expression
	 */
    macro public static function debug(message:Expr):Expr {
        return logMacro(DEBUG, message);
    }

    /*
	 * Generates INFO log level expression
	 */
    macro public static function info(message:Expr):Expr {
        return logMacro(INFO, message);
    }

    /*
	 * Generates WARN log level expression
	 */
    macro public static function warn(message:Expr):Expr {
        return logMacro(WARN, message);
    }

    /*
	 * Generates ERROR log level expression
	 */
    macro public static function error(message:Expr):Expr {
        return logMacro(ERROR, message);
    }

    /*
	 * Generates FATAL log level expression
	 */
    macro public static function fatal(message:Expr):Expr {
        return logMacro(FATAL, message);
    }
}
