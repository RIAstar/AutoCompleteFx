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

package net.riastar.components {

import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import flashx.textLayout.operations.CutOperation;
import flashx.textLayout.operations.DeleteTextOperation;
import flashx.textLayout.operations.FlowOperation;

import mx.collections.IList;
import mx.collections.ListCollectionView;
import mx.core.mx_internal;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import spark.components.RichEditableText;
import spark.components.supportClasses.DropDownListBase;
import spark.components.supportClasses.ListBase;
import spark.components.supportClasses.SkinnableTextBase;
import spark.events.DropDownEvent;
import spark.events.TextOperationEvent;


use namespace mx_internal;

/**
 * A Spark implementation of an AutoComplete component.
 *
 * @author RIAstar
 */
public class AutoComplete extends DropDownListBase {

    /* ----------------- */
    /* --- skinparts --- */
    /* ----------------- */

    [SkinPart(required="true")]
    /**
     * Skin part that holds the input text, or the <code>selectedItem</code> text when <code>singleSelection</code> is <code>true</code>.
     */
    public var textInput:SkinnableTextBase;

    [SkinPart(required="false")]
    /**
     * Optional skin part that displays the selected items.
     */
    public var selectionList:ListBase;


    /* ------------------------- */
    /* --- public properties --- */
    /* ------------------------- */

    /**
     * The data that was originally provided, i.e. an unfiltered data set.
     * Note that it is still possible to use a <code>filterFunction</code> on this data.
     */
    private var originalData:IList;

    /**
     * A wrapper around the <code>originalData</code> that filters out suggestions to be displayed in the dropdown List.
     */
    private var suggestionView:ListCollectionView;

    /**
     * The data that is externally set is only used internally. We provide the dropdown List with a wrapper
     * that filters out suggestions to be displayed in it.
     *
     * @inheritDoc
     */
    override public function get dataProvider():IList {
        return originalData;
    }
    override public function set dataProvider(value:IList):void {
        if (originalData) originalData.removeEventListener(CollectionEvent.COLLECTION_CHANGE, originalDataChangeHandler);
        originalData = value;

        if (value) {
            suggestionView = new ListCollectionView(value);
            suggestionView.filterFunction = canSuggest;
            originalData.addEventListener(CollectionEvent.COLLECTION_CHANGE, originalDataChangeHandler, false, 0, true);
        }
        else suggestionView = null;

        super.dataProvider = suggestionView;
    }

    /**
     * By default <code>AutoComplete</code> allows the user to select multiple items.
     * Set this property to <code>true</code> if you want only one item to be selected at a time.
     * The selected item will then be displayed in the <code>textInput</code> instead of a separate List.
     *
     * (Note: we cannot use <code>List#allowMultipleSelection</code> for this, since it was excluded in <code>DropDownListBase</code>)
     *
     * @default false
     */
    public var singleSelection:Boolean;

    /**
     * Have to hack it this way because <code>DropDownListBase</code> doesn't allow setting <code>allowMultipleSelection</code>,
     * but of course we require multiple selections in an AutoComplete component...
     *
     * @private
     * @default true
     */
    override public function get allowMultipleSelection():Boolean {
        return true;
    }


    /* -------------------------------------- */
    /* --- wrapped 'textInput' properties --- */
    /* -------------------------------------- */

    /**
     * Flag that determines whether the <code>textInput</code> properties have to be committed.
     */
    private var textInputPropertyChanged:Boolean = false;

    private var _maxChars:int = 0;
    [Inspectable(category="General", defaultValue="0")]
    public function get maxChars():int {
        return _maxChars;
    }
    public function set maxChars(value:int):void {
        _maxChars = value;
        textInputPropertyChanged = true;
        invalidateProperties();
    }

    private var _prompt:String;
    [Inspectable(category="General")]
    public function get prompt():String {
        return _prompt;
    }
    public function set prompt(value:String):void {
        _prompt = value;
        textInputPropertyChanged = true;
        invalidateProperties();
    }

    private var _restrict:String;
    [Inspectable(category="General", defaultValue="")]
    public function get restrict():String {
        return _restrict;
    }
    public function set restrict(value:String):void {
        _restrict = value;
        textInputPropertyChanged = true;
        invalidateProperties();
    }


    /* --------------------------- */
    /* --- internal properties --- */
    /* --------------------------- */

    /** A list of words that have to be matched for an item to show up as a suggestion. */
    private var searchTerms:Vector.<String>;

    /** The number of words that have to be matched for an item to show up as a suggestion. */
    private var numSearchTerms:int;

    /** Whether the <code>textInput</code> currently has focus: determines how keyboard input will be handled. */
    private var isTextInputInFocus:Boolean;

    /** A flag that determines whether the user input will be cleared in <code>commitProperties()</code>. */
    private var markedForReset:Boolean;


    /* -------------------- */
    /* --- construction --- */
    /* -------------------- */

    /**
     * Track keyboard actions in the capture phase.
     * @private
     */
    override public function initialize():void {
        super.initialize();
        addEventListener(KeyboardEvent.KEY_DOWN, captureKeyDownHandler, true);
    }

    /**
     * Track immediate text changes and focus events in the <code>textInput</code>.
     */
    protected function initializeTextInput():void {
        textInput.addEventListener(TextOperationEvent.CHANGE, textInputChangeHandler);
        textInput.addEventListener(FocusEvent.FOCUS_IN, textInputFocusInHandler, true);
        textInput.addEventListener(FocusEvent.FOCUS_OUT, textInputFocusOutHandler, true);
        textInput.focusEnabled = false;

        //fire a change event on every keystroke
        if (textInput.textDisplay is RichEditableText)
            RichEditableText(textInput.textDisplay).batchTextInput = false;

        textInputPropertyChanged = true;
        invalidateProperties();
    }

    override protected function partAdded(partName:String, instance:Object):void {
        super.partAdded(partName, instance);

        switch (instance) {
            case textInput:
                initializeTextInput();
                break;
        }
    }


    /* ---------------------- */
    /* --- event handlers --- */
    /* ---------------------- */

    /**
     * When the <code>textInput</code> gets focus, set the flag.
     *
     * @param event
     */
    private function textInputFocusInHandler(event:FocusEvent):void {
        isTextInputInFocus = true;
    }

    /**
     * When the <code>textInput</code> loses focus, unset the flag.
     * @param event
     */
    private function textInputFocusOutHandler(event:FocusEvent):void {
        isTextInputInFocus = false;
    }

    /**
     * When the List has focus, treat KeyboardEvents normally.
     *
     * @param event
     */
    override protected function keyDownHandler(event:KeyboardEvent):void {
        if (isTextInputInFocus) return;

        processKey(event.keyCode);
        super.keyDownHandler(event);
    }

    /**
     * When <code>textInput</code> has focus, catch the KeyboardEvents in the <code>capture</code> phase
     * so that we can process the navigation keys (UP/DOWN, PageUp/PageDown, HOME/END).
     *
     * @param event
     */
    private function captureKeyDownHandler(event:KeyboardEvent):void {
        if (!isTextInputInFocus) return;

        processKey(event.keyCode);
        super.keyDownHandler(event);
    }

    /**
     * When <code>textInput.text</code> changes, process the text operation.
     *
     * @param event
     */
    private function textInputChangeHandler(event:TextOperationEvent):void {
        processTextOperation(event.operation);
    }

    /**
     * When the original data changes in any way (add, remove, filter, ...), filter the suggestions accordingly.
     *
     * @param event
     */
    private function originalDataChangeHandler(event:CollectionEvent):void {
        if (suggestionView) suggestionView.refresh();
    }

    /**
     * When the suggestion list changes, make sure the first item is highlighted for immediate selection.
     * This overrides the original behaviour, which is to deselect everything.
     */
    override mx_internal function dataProviderRefreshed():void {
        highlightFirst();
    }

    /**
     * When the dropdown is opened, make sure the first item is highlighted for immediate selection.
     * This overrides the original behaviour, which is to highlight the current <code>selectedIndex</code>.
     *
     * @param event
     */
    override mx_internal function open_updateCompleteHandler(event:FlexEvent):void {
        removeEventListener(FlexEvent.UPDATE_COMPLETE, open_updateCompleteHandler);
        highlightFirst();
        dispatchEvent(new DropDownEvent(DropDownEvent.OPEN));
    }

    /**
     * Prevent the default behaviour when the dropdown closes, which is to select the <code>userProposedSelectedIndex</code>.
     *
     * @param event
     */
    override protected function dropDownController_closeHandler(event:DropDownEvent):void {
        event.preventDefault();
        super.dropDownController_closeHandler(event);
    }


    /* ----------------- */
    /* --- behaviour --- */
    /* ----------------- */

    /**
     * Highlights the first item in the suggestion List.
     */
    protected function highlightFirst():void {
        if (isDropDownOpen && suggestionView.length) callLater(changeHighlightedSelection, [0, true]);
    }

    /**
     * Additional keyboard navigation on top of what <code>DropDownListBase</code> does.
     * <ul>
     *     <li>ENTER: select the currently highlighted item</li>
     *     <li>ESCAPE: clear the <code>textInput</code> and close the dropdown</li>
     * </ul>
     *
     * @param code  The code of the key to be processed.
     */
    protected function processKey(code:uint):void {
        switch (code) {
            case Keyboard.ENTER:
                trace("processKey ENTER");
                setSelectedIndices(calculateSelectedIndices(userProposedSelectedIndex, false, false), true);
                break;
            case Keyboard.ESCAPE:
                trace("processKey ESCAPE");
                reset();
                break;
        }
    }

    /**
     * Processes all kinds of text operations: when text is removed (delete, cut) the first item is highlighted,
     * otherwise the dropdown is opened and the text processed.
     *
     * @param operation The text operation to be processed.
     */
    protected function processTextOperation(operation:FlowOperation):void {
        if (operation is DeleteTextOperation || operation is CutOperation)
            highlightFirst();
        else {
            if (!isDropDownOpen) openDropDown();
            processText(textInput.text);
        }
    }

    /**
     * Filters the suggestion list based on the words in <code>text</code>.
     *
     * @param text  The text that will be used to filter the suggestions.
     */
    protected function processText(text:String):void {
        if (!text) text = "";

        searchTerms = Vector.<String>(StringUtil.trim(text).split(/\s+/g));
        numSearchTerms = searchTerms.length;

        if (suggestionView) suggestionView.refresh();
    }

    /**
     * Resets the user input. The net result will be an empty <code>textInput</code> and a closed dropdown.
     */
    public function reset():void {
        //We only set a flag here: the actual clearing happens in 'commitProperties()'
        userProposedSelectedIndex = -1;
        markedForReset = true;
        invalidateProperties();
    }

    /**
     * The <code>filterFunction</code> for the suggestion list. There are two rules:
     * <ul>
     *     <li>already selected items are no longer suggested</li>
     *     <li>an item's label representation must contain all the words from the user input</li>
     * </ul>
     *
     * @param item  The item to be validated.
     * @return Whether the item can be suggested or not.
     */
    protected function canSuggest(item:*):Boolean {
        if (selectedItems && selectedItems.indexOf(item) != -1) return false;

        var label:String = itemToLabel(item);
        var count:int = 0;

        for each (var term:String in searchTerms) {
            if (label.search(new RegExp(term, "gi")) > -1)
                count++;
            else return false;
        }

        return count == numSearchTerms;
    }

    /**
     * We completely override how the selected indices are calculated:
     * we take the current <code>selectedIndices</code> and add the provided <code>index</code> to it.
     * (The default behaviour is much more complex and depends on the Ctrl and Shift keys)
     *
     * @param index     The index of the item that wants to be added to the selection.
     * @param shiftKey  <strong>ignored</strong>
     * @param ctrlKey   <strong>ignored</strong>
     * @return The updated item indices that the new selection will be committed to.
     */
    override protected function calculateSelectedIndices(index:int, shiftKey:Boolean, ctrlKey:Boolean):Vector.<int> {
        //don't add negative indices
        if (index < 0) return selectedIndices;

        //don't add indices that are already selected
        var originalDataIndex:int = originalData.getItemIndex(suggestionView.getItemAt(index));
        if (selectedIndices.indexOf(originalDataIndex) != -1) return selectedIndices;

        //clone the Vector to force a refresh of 'selectedIndices'
        var clone:Vector.<int> = Vector.<int>(ObjectUtil.copy(selectedIndices));
        clone.push(originalDataIndex);
        return clone;
    }

    /**
     * Whenever the selection changes, reset the user input.
     *
     * @private
     * @inheritDoc
     */
    override mx_internal function setSelectedIndices(value:Vector.<int>, dispatchChangeEvent:Boolean = false, changeCaret:Boolean = true):void {
        super.setSelectedIndices(value, dispatchChangeEvent, changeCaret);
        reset();
    }

    /**
     * Because this a drop down list, <code>dataGroup</code> might not exist.
     *
     * @private
     */
    override mx_internal function changeHighlightedSelection(newIndex:int, scrollToTop:Boolean = false):void {
        if (dataGroup) super.changeHighlightedSelection(newIndex, scrollToTop);
    }

    /**
     * Prevent the default behaviour of <code>DropDownListBase</code> to automatically select the item
     * that starts with what the user typed.
     *
     * @param eventCode <strong>ignored</strong>
     * @return false
     */
    override mx_internal function findKey(eventCode:int):Boolean {
        return false;
    }

    /**
     * Commit wrapped <code>textInput</code> properties.
     * Commit reset requests.
     * 
     * @inheritDoc
     */
    override protected function commitProperties():void {
        super.commitProperties();

        if (textInput && textInputPropertyChanged) {
            textInput.maxChars = _maxChars;
            textInput.prompt = _prompt;
            textInput.restrict = _restrict;

            textInputPropertyChanged = false;
        }

        if (textInput && markedForReset) {
            textInput.text = "";
            processText("");
            highlightFirst();

            markedForReset = false;
        }
    }

}

}