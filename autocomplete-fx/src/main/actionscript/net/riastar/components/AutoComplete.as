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

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import mx.collections.IList;
import mx.collections.ListCollectionView;
import mx.core.IVisualElement;
import mx.core.mx_internal;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import spark.components.List;
import spark.components.RichEditableText;
import spark.components.supportClasses.DropDownListBase;
import spark.components.supportClasses.SkinnableTextBase;
import spark.events.DropDownEvent;
import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;
import spark.layouts.supportClasses.LayoutBase;


use namespace mx_internal;

[Exclude(name="allowMultipleSelection", kind="property")]

/* -------------- */
/* --- styles --- */
/* -------------- */

/**
 * Color of the matched text.
 *
 * @default 0xff0000
 */
[Style(name="matchColor", type="uint", format="Color", inherit="yes")]

/**
 * Determines whether the matched text is italic font.
 *
 * @default normal
 */
[Style(name="matchFontStyle", type="String", enumeration="normal,italic", inherit="yes")]

/**
 * Determines whether the matched text is boldface.
 *
 * @default bold
 */
[Style(name="matchFontWeight", type="String", enumeration="normal,bold", inherit="yes")]

/**
 * Alpha (transparency) value for the matched text.
 *
 * @default 1.0
 */
[Style(name="matchTextAlpha", type="Number", inherit="yes", minValue="0.0", maxValue="1.0")]

/**
 * Determines whether the matched text is underlined.
 *
 * @default none
 */
[Style(name="matchTextDecoration", type="String", enumeration="none,underline", inherit="yes")]

/**
 *  Bottom inset, in pixels, for the text in the prompt area of the control.
 *
 *  @default 3
 */
[Style(name="paddingBottom", type="Number", format="Length", inherit="no")]

/**
 *  Left inset, in pixels, for the text in the prompt area of the control.
 *
 *  @default 3
 */
[Style(name="paddingLeft", type="Number", format="Length", inherit="no")]

/**
 *  Right inset, in pixels, for the text in the prompt area of the control.
 *
 *  @default 3
 */
[Style(name="paddingRight", type="Number", format="Length", inherit="no")]

/**
 *  Top inset, in pixels, for the text in the prompt area of the control.
 *
 *  @default 5
 */
[Style(name="paddingTop", type="Number", format="Length", inherit="no")]


/* ------------------- */
/* --- skin states --- */
/* ------------------- */

/**
 * Same as the <code>normal</code> state, but with a selection to be shown.
 */
[SkinState("normalWithSelection")]

/**
 * Same as the <code>open</code> state, but with a selection to be shown.
 */
[SkinState("openWithSelection")]

/**
 * Same as the <code>disabled</code> state, but with a selection to be shown.
 */
[SkinState("disabledWithSelection")]


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

    private var _selectionList:List;
    [SkinPart(required="false")]
    /**
     * Optional skin part that displays the selected items.
     * Note that you can also set a List defined outside the component here.
     * This external List will then replace the <code>selectionList</code> defined in the skin (if any)
     * and display a similar behaviour, except it will not be automatically hidden when no values are selected;
     * it is up to the developer to decide whether he wants this behaviour or not.
     */
    public function get selectionList():List {
        return _selectionList;
    }
    public function set selectionList(value:List):void {
        if (!isExternalSelectionList) {
            destroySelectionList();
            _selectionList = value;
            initializeSelectionList();
        }

        if (value && !skin) isExternalSelectionList = true;
    }


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
     * A wrapper around the <code>originalData</code> that filters out selected items to be displayed in the <code>selectionList</code>.
     */
    private var selectionView:ListCollectionView;

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
        if (selectionView) selectionView.removeEventListener(CollectionEvent.COLLECTION_CHANGE, selectionChangeHandler);
        originalData = value;

        if (value) {
            suggestionView = new ListCollectionView(value);
            suggestionView.filterFunction = canSuggest;

            selectionView = new ListCollectionView(value);
            selectionView.filterFunction = isSelected;
            selectionView.refresh();
            initializeSelectionList();

            originalData.addEventListener(CollectionEvent.COLLECTION_CHANGE, originalDataChangeHandler, false, 0, true);
            selectionView.addEventListener(CollectionEvent.COLLECTION_CHANGE, selectionChangeHandler, false, 0, true);
        }
        else suggestionView = null;

        super.dataProvider = suggestionView;
    }

    private var _singleSelection:Boolean;
    /**
     * By default <code>AutoComplete</code> allows the user to select multiple items.
     * Set this property to <code>true</code> if you want only one item to be selected at a time.
     * The selected item will then be displayed in the <code>textInput</code> instead of a separate List.
     *
     * (Note: we cannot use <code>List#allowMultipleSelection</code> for this, since it was excluded in <code>DropDownListBase</code>)
     *
     * @default false
     */
    public function get singleSelection():Boolean {
        return _singleSelection;
    }
    public function set singleSelection(value:Boolean):void {
        _singleSelection = value;
        setSelectedIndices(null, true);
        if (selectionView) selectionView.refresh();
    }

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

    private var _displayOpenButton:Boolean = true;
    /**
     * Whether <code>DropDownListBase</code>'s <code>openButton</code> must be displayed or not.
     * Since it is shown by default, an <code>AutoComplete</code> look exactly like a <code>DropDownList</code>.
     *
     * @default true
     */
    public function get displayOpenButton():Boolean {
        return _displayOpenButton;
    }
    public function set displayOpenButton(value:Boolean):void {
        _displayOpenButton = value;
        invalidateProperties();
    }

    /**
     * Make sure FormItem labels are aligned properly to the textInput's text.
     *
     * @private
     */
    override public function get baselinePosition():Number {
        return textInput.baselinePosition;
    }

    override public function get selectedIndices():Vector.<int> {
        return super.selectedIndices;
    }
    override public function set selectedIndices(value:Vector.<int>):void {
        super.selectedIndices = value;
    }

    override public function get selectedItems():Vector.<Object> {
        return super.selectedItems;
    }
    override public function set selectedItems(value:Vector.<Object>):void {
        super.selectedItems = value;
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


    /* ------------------------------------------ */
    /* --- wrapped 'selectionList' properties --- */
    /* ------------------------------------------ */

    private var selectionListPropertyChanged:Boolean = false;

    private var _selectionLayout:LayoutBase;
    [Inspectable(category="General")]
    public function get selectionLayout():LayoutBase {
        return _selectionLayout;
    }
    public function set selectionLayout(value:LayoutBase):void {
        _selectionLayout = value;
        selectionListPropertyChanged = true;
        invalidateProperties();
    }


    /* --------------------------- */
    /* --- internal properties --- */
    /* --------------------------- */

    /** A list of words that have to be matched for an item to show up as a suggestion. */
    private var searchTerms:Vector.<String>;

    /** The number of words that have to be matched for an item to show up as a suggestion. */
    private var numSearchTerms:int;

    /**
     * A regular expression that matches all the search terms.
     * It is used in the ItemRenderers to highlight the matched terms, but stored here to limit instantiation.
     */
    private var searchRegex:RegExp;

    /** Whether the <code>textInput</code> currently has focus: determines how keyboard input will be handled. */
    private var isTextInputInFocus:Boolean;

    /** A flag that determines whether the user input will be cleared in <code>commitProperties()</code>. */
    private var markedForReset:Boolean;

    /** Whether the <code>selectionList</code> was created outside the component or is part of then skin. */
    private var isExternalSelectionList:Boolean;


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

    /**
     * Sets the dataProvider and refreshes it immediately.
     * Track user selection.
     */
    protected function initializeSelectionList():void {
        if (!_selectionList) return;

        _selectionList.dataProvider = selectionView;
        _selectionList.focusEnabled = false;
        _selectionList.addEventListener(IndexChangeEvent.CHANGE, selectionIndexChangeHandler);
    }

    override protected function partAdded(partName:String, instance:Object):void {
        super.partAdded(partName, instance);

        switch (instance) {
            case textInput:
                initializeTextInput();
                break;
            case _selectionList:
                initializeSelectionList();
                break;
        }
    }


    /* ---------------------- */
    /* --- event handlers --- */
    /* ---------------------- */

    /**
     * When the <code>textInput</code> gets focus, set the flag and select all the text.
     *
     * @param event
     */
    private function textInputFocusInHandler(event:FocusEvent):void {
        isTextInputInFocus = true;
        textInput.selectAll();
    }

    /**
     * When the <code>textInput</code> loses focus, unset the flag and remove invalid user input.
     *
     * @param event
     */
    private function textInputFocusOutHandler(event:FocusEvent):void {
        isTextInputInFocus = false;
        if (!_singleSelection || selectedIndex == -1) reset();
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
     * When <code>textInput.text</code> changes, start showing suggestions.
     *
     * @param event
     */
    private function textInputChangeHandler(event:TextOperationEvent):void {
        startSuggesting();
    }

    /**
     * When the original data changes in any way (add, remove, filter, ...), filter the suggestions accordingly.
     *
     * @param event
     */
    private function originalDataChangeHandler(event:CollectionEvent):void {
        if (suggestionView) suggestionView.refresh();
        if (selectionView) selectionView.refresh();
    }

    /**
     * When the selection changes, invalidate the skin state.
     * TODO remove the necessity for 'callLater' (because the 'selectionList' is refreshed in 'commitSelection')
     *
     * @param event
     */
    private function selectionChangeHandler(event:CollectionEvent):void {
        callLater(invalidateSkinState);
    }

    /**
     * When an item is selected in the <code>selectionList</code> we remove that item from the <code>selectedIndices</code>.
     *
     * @param event
     */
    private function selectionIndexChangeHandler(event:IndexChangeEvent):void {
        if (event.newIndex != -1) removeSelectedIndex(event.newIndex);
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
                setSelectedIndices(calculateSelectedIndices(userProposedSelectedIndex, false, false), true);
                if (!_singleSelection || !suggestionView.length) reset();
                break;
            case Keyboard.ESCAPE:
                reset();
                break;
        }
    }

    /**
     * Opens the dropdown and processes the user input to display matching suggestions.
     * In <code>singleSelection</code> mode the selected item is reset from the moment the user starts typing.
     */
    protected function startSuggesting():void {
        if (!isDropDownOpen) openDropDown();
        if (_singleSelection && selectedIndex > -1) setSelectedIndices(null, true);
        processText(textInput.text);
    }

    /**
     * Filters the suggestion list based on the words in <code>text</code>.
     *
     * @param text  The text that will be used to filter the suggestions.
     */
    protected function processText(text:String):void {
        if (!text) text = "";
        text = StringUtil.trim(text);

        if (text == "") {
            numSearchTerms = 0;
            searchRegex = null;
        }
        else {
            searchTerms = Vector.<String>(text.split(/\s+/g));
            numSearchTerms = searchTerms.length;
            searchRegex = searchTerms && searchTerms.length ? new RegExp(searchTerms.join("|"), "gi") : null;
        }

        if (suggestionView) suggestionView.refresh();
    }

    /**
     * Resets the user input. The net result will be an empty <code>textInput</code> and a closed dropdown.
     */
    public function reset():void {
        //We only set a flag here: the actual clearing happens in 'commitProperties()'
        userProposedSelectedIndex = -1;
        markedForReset = true;
        if (_singleSelection && selectedIndex > -1) setSelectedIndices(null, true);
        invalidateProperties();
    }

    /**
     * The <code>filterFunction</code> for the suggestion list. There are three rules:
     * <ul>
     *     <li>already selected items are no longer suggested</li>
     *     <li>if there is no user input, all items can be suggested (except the ones that are already selected)</li>
     *     <li>an item's label representation must contain all the words from the user input</li>
     * </ul>
     *
     * @param item The item to be validated.
     * @return Whether the item can be suggested or not.
     */
    protected function canSuggest(item:*):Boolean {
        try {
            //filter out already selected items
            if (selectedItems.indexOf(item) != -1) return false;
        }
        catch (e:Error) {
            //someone is trying to reset and refresh at the same time: swallow nullpointers
        }

        //show all remaining items when there is no user input
        if (!numSearchTerms) return true;

        //match all the words from the user input
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
     * The <code>filterFunction</code> for the <code>selectionList</code>.
     *
     * @param item The item to be validated.
     * @return Whether the item can be shown in the <code>selectionList</code> or not.
     */
    protected function isSelected(item:*):Boolean {
        try {
            return selectedItems.indexOf(item) != -1;
        }
        catch (e:Error) {
            //someone is trying to reset and refresh at the same time: swallow nullpointers
        }

        return false;
    }

    /**
     * We completely override how the selected indices are calculated:
     * we take the current <code>selectedIndices</code> and add the provided <code>index</code> to it.
     * (The default behaviour is much more complex and depends on the Ctrl and Shift keys)
     *
     * @param index     The index of the item that is being added to the selection.
     * @param shiftKey  <strong>ignored</strong>
     * @param ctrlKey   <strong>ignored</strong>
     * @return The updated item indices that the new selection will be committed to.
     */
    override protected function calculateSelectedIndices(index:int, shiftKey:Boolean, ctrlKey:Boolean):Vector.<int> {
        //don't add negative indices
        if (index < 0 || !suggestionView.length) return selectedIndices;

        //don't add indices that are already selected
        var originalDataIndex:int = originalData.getItemIndex(suggestionView.getItemAt(index));
        if (selectedIndices.indexOf(originalDataIndex) != -1) return selectedIndices;

        //in single selection mode, just return a Vector with one index
        if (singleSelection) return Vector.<int>([originalDataIndex]);

        //clone the Vector to force a refresh of 'selectedIndices'
        var clone:Vector.<int> = Vector.<int>(ObjectUtil.copy(selectedIndices));
        clone.push(originalDataIndex);
        clone.sort(compareOriginalIndices);
        return clone;
    }

    /**
     * Used to sort the <code>selectedIndices</code> in the same order as the <code>originalData</code>.
     *
     * @param a The first <code>originalData</code> index to compare.
     * @param b The second <code>originalData</code> index to compare.
     * @return 0 if <code>a == b</code>; a positive Number if <code>a > b</code>; a negative Number if <code>b > a</code>
     */
    protected static function compareOriginalIndices(a:int, b:int):Number {
        return a - b;
    }

    /**
     * Removes the provided index from the <code>selectionList</code>.
     *
     * @param index The index to be removed.
     */
    protected function removeSelectedIndex(index:int):void {
        _selectionList.selectedIndices = null; //don't do `selectedIndex = -1`: it will be overridden internally
        setSelectedIndices(calculateSelectedIndicesAfterRemoval(index), true);
    }

    /**
     * Calculates the selected indices after an index has been removed:
     * we take the current <code>selectedIndices</code> and remove the provided <code>index</code> from it.
     *
     * @param index The index of the item that is being removed from the selection.
     * @return The updated item indices that the new selection will be committed to.
     */
    protected function calculateSelectedIndicesAfterRemoval(index:int):Vector.<int> {
        //don't remove negative indices
        if (index < 0) return selectedIndices;

        //clone the Vector to force a refresh of 'selectedIndices'
        var clone:Vector.<int> = Vector.<int>(ObjectUtil.copy(selectedIndices));
        clone.splice(index, 1);
        return clone;
    }

    /**
     * Because this a drop down list, <code>dataGroup</code> might not exist.
     *
     * @private
     */
    override mx_internal function changeHighlightedSelection(newIndex:int, scrollToTop:Boolean = false):void {
        if (dataGroup && isDropDownOpen) super.changeHighlightedSelection(newIndex, scrollToTop);
    }

    /**
     * Automatically set the focus on the <code>textInput</code>.
     */
    override public function setFocus():void {
        if (stage && textInput) stage.focus = textInput.textDisplay as InteractiveObject;
    }

    /**
     * Need to override this if we want the focus border to be drawn in combination with our implementation of <code>setFocus()</code>.
     *
     * @inheritDoc
     */
    override protected function isOurFocus(target:DisplayObject):Boolean {
        return textInput && target == textInput.textDisplay;
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

        if (selectionList && selectionListPropertyChanged) {
            selectionListPropertyChanged = false;

            selectionList.layout = _selectionLayout;
        }

        if (openButton) openButton.visible = openButton.includeInLayout = _displayOpenButton;
        if (!textInput) return;

        if (textInputPropertyChanged) {
            textInputPropertyChanged = false;

            textInput.maxChars = _maxChars;
            textInput.prompt = _prompt;
            textInput.restrict = _restrict;
        }

        if (markedForReset) {
            markedForReset = false;

            textInput.text = "";
            processText("");
            highlightFirst();
        }
    }

    /**
     * Update the item renderers with the regular expression.
     *
     * @inheritDoc
     */
    override public function updateRenderer(renderer:IVisualElement, itemIndex:int, data:Object):void {
        super.updateRenderer(renderer, itemIndex, data);
        if (renderer is ISuggestionRenderer) ISuggestionRenderer(renderer).searchTerms = searchRegex;
    }

    /**
     * Whenever the selection changes, update the <code>selectionView</code> and reset the user input.
     *
     * @inheritDoc
     */
    override protected function commitSelection(dispatchChangedEvents:Boolean = true):Boolean {
        var committed:Boolean = super.commitSelection(dispatchChangedEvents);
        if (!committed) return false;

        if (_singleSelection) {
            if (selectedIndex > -1) {
                textInput.text = itemToLabel(selectedItem);
                textInput.selectAll();
                processText("");
            }
        }
        else {
            if (selectionView) selectionView.refresh();
            reset();
        }

        return true;
    }

    /**
     * @return <code>DropDownListBase</code>'s current skin state (<code>normal,open,disabled</code>),
     * appended with <code>"WithSelection"</code> if there are any selected items in multi-select mode.
     * If an external List was provided, we never show the selection list defined in the skin.
     */
    override protected function getCurrentSkinState():String {
        var state:String = super.getCurrentSkinState();
        if (!singleSelection && !isExternalSelectionList && selectionView && selectionView.length)
            state += "WithSelection";
        return state;
    }


    /* ------------------- */
    /* --- destruction --- */
    /* ------------------- */

    override protected function partRemoved(partName:String, instance:Object):void {
        switch (instance) {
            case textInput:
                destroyTextInput();
                break;
            case _selectionList:
                destroySelectionList();
                break;
        }

        super.partRemoved(partName, instance);
    }

    /**
     * Stop tracking text changes and focus events in the <code>textInput</code>.
     */
    protected function destroyTextInput():void {
        if (!textInput) return;

        textInput.removeEventListener(TextOperationEvent.CHANGE, textInputChangeHandler);
        textInput.removeEventListener(FocusEvent.FOCUS_IN, textInputFocusInHandler, true);
        textInput.removeEventListener(FocusEvent.FOCUS_OUT, textInputFocusOutHandler, true);
    }

    /**
     * Stop tracking user selection.
     */
    protected function destroySelectionList():void {
        if (_selectionList) _selectionList.removeEventListener(IndexChangeEvent.CHANGE, selectionIndexChangeHandler);
    }

}
}
