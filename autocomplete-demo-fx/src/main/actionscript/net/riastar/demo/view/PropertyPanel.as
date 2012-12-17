/*
 * Copyright (c) 2012 Maxime Cowez a.k.a. RIAstar.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 * OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * @author RIAstar
 */
package net.riastar.demo.view {

import spark.components.supportClasses.SkinnableComponent;


public class PropertyPanel extends SkinnableComponent {

    //properties

    [Bindable]
    public var singleSelection:Boolean;

    [Bindable]
    public var displayOpenButton:Boolean = true;

    [Bindable]
    public var maxChars:int = 0;

    [Bindable]
    public var prompt:String;

    private var _restrict:String;
    [Bindable]
    public function get restrict():String {
        return _restrict;
    }
    public function set restrict(value:String):void {
        _restrict = value == "" ? null : value;
    }


    //styles

    [Bindable]
    public var matchColor:uint = 0xff0000;

    [Bindable]
    public var matchFontStyle:Object = "normal";

    [Bindable]
    public var matchFontWeight:Object = "bold";

    [Bindable]
    public var matchTextAlpha:Number = 1;

    [Bindable]
    public var matchTextDecoration:Object = "none";

}

}
