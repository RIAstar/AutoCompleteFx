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
package net.riastar.components.gridClasses {

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import mx.collections.IList;
import mx.core.IFactory;
import mx.events.FlexEvent;

import spark.components.gridClasses.GridItemEditor;
import spark.components.supportClasses.DropDownListBase;
import spark.components.supportClasses.ListBase;


public class ListGridItemEditor extends GridItemEditor {

    /* ------------------ */
    /* --- components --- */
    /* ------------------ */

    public var list:ListBase;


    /* ------------------------- */
    /* --- public properties --- */
    /* ------------------------- */

    override public function get value():Object {
        var item:Object = list.selectedItem;
        if (item) return item;

        //hack: GridItemEditor#save crashes if 'value' is 'null' and this column's data type is primitive
        var ti:Object = list.typicalItem;
        if (ti && (ti is String || ti is int || ti is uint || ti is Number || ti is Boolean))
            return new ti.constructor();

        return null;
    }
    override public function set value(newValue:Object):void {
        list.selectedItem = newValue;
    }

    private var _dataProvider:IList;
    [Bindable("listGridItemEditorDataProviderChanged")]
    public function get dataProvider():IList {
        return _dataProvider;
    }
    public function set dataProvider(value:IList):void {
        if (_dataProvider == value) return;

        _dataProvider = value;
        if (list) list.dataProvider = value;
        dispatchEvent(new Event("listGridItemEditorDataProviderChanged"));
    }

    public var listFactory:IFactory;


    /* -------------------- */
    /* --- construction --- */
    /* -------------------- */

    override protected function createChildren():void {
        super.createChildren();

        if (!list) {
            if (listFactory) list = listFactory.newInstance();
            else throw new Error(
                    "ListGridItemEditor needs to have at least a 'list' or a 'listFactory' value to work properly."
            );
        }

        list.percentWidth = list.percentHeight = 100;
        list.dataProvider = _dataProvider;
        addElement(list);
    }

    override public function prepare():void {
        super.prepare();

        if (list is DropDownListBase) DropDownListBase(list).openDropDown();
        list.addEventListener(KeyboardEvent.KEY_DOWN, stopEnterEvents, true);
        list.addEventListener(FlexEvent.VALUE_COMMIT, handleValueCommit);
    }

    private function stopEnterEvents(event:KeyboardEvent):void {
        if (event.keyCode == Keyboard.ENTER) event.stopImmediatePropagation();
    }

    private function handleValueCommit(event:FlexEvent):void {
        if (!list.selectedItem) return;

        list.removeEventListener(FlexEvent.VALUE_COMMIT, handleValueCommit);
        list.removeEventListener(KeyboardEvent.KEY_DOWN, stopEnterEvents, true);
        callLater(dataGrid.endItemEditorSession);
    }


    /* ----------------- */
    /* --- behaviour --- */
    /* ----------------- */

    override public function setFocus():void {
        list.setFocus();
    }

}

}
