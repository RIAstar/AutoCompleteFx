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


import mx.events.PropertyChangeEvent;

import spark.components.TextArea;


public class CodeArea extends TextArea {

    private var _properties:PropertyPanel;
    public function get properties():PropertyPanel {
        return _properties;
    }
    public function set properties(value:PropertyPanel):void {
        if (_properties) _properties.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, handlePropertyChange);
        _properties = value;
        invalidateProperties();
        if (value) value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, handlePropertyChange);
    }

    private function handlePropertyChange(event:PropertyChangeEvent):void {
        invalidateProperties();
    }

    override protected function commitProperties():void {
        super.commitProperties();
        if (!properties) return;

        var props:Array = ['<rs:AutoComplete dataProvider="{dp}"'];

        //properties
        if (properties.singleSelection)
            props.push('singleSelection="true"');
        if (!properties.displayOpenButton)
            props.push('displayOpenButton="false"');
        if (properties.maxChars)
            props.push('maxChars="' + properties.maxChars + '"');
        if (properties.prompt && properties.prompt.length)
            props.push('prompt="' + properties.prompt + '"');
        if (properties.restrict && properties.restrict.length)
            props.push('maxChars="' + properties.restrict + '"');

        //styles
        if (properties.matchColor != 0xff0000)
            props.push('matchColor="0x' + properties.matchColor.toString(16) + '"');
        if (properties.matchFontStyle != "normal")
            props.push('matchFontStyle="' + properties.matchFontStyle + '"');
        if (properties.matchFontWeight != "bold")
            props.push('matchFontWeight="' + properties.matchFontWeight + '"');
        if (properties.matchTextAlpha != 1)
            props.push('matchTextAlpha="' + properties.matchTextAlpha + '"');
        if (properties.matchTextDecoration != "none")
            props.push('matchTextDecoration="' + properties.matchTextDecoration + '"');

        text = props.join("\n                 ") + ' />';
    }

}

}
