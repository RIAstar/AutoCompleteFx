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

package net.riastar.skins.spark {

import net.riastar.components.ISuggestionRenderer;

import spark.components.RichText;
import spark.skins.spark.DefaultItemRenderer;
import spark.utils.TextFlowUtil;


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
 * @author RIAstar
 */
public class SuggestionItemRenderer extends DefaultItemRenderer implements ISuggestionRenderer {

    /* ------------------ */
    /* --- properties --- */
    /* ------------------ */

    private var searchTermsChanged:Boolean;

    private var _searchTerms:RegExp;
    public function get searchTerms():RegExp {
        return _searchTerms;
    }
    public function set searchTerms(value:RegExp):void {
        searchTermsChanged = _searchTerms != value;
        _searchTerms = value;
        invalidateProperties();
    }


    /* --------------------------- */
    /* --- internal properties --- */
    /* --------------------------- */

    private var richText:RichText;


    /* -------------------- */
    /* --- construction --- */
    /* -------------------- */

    override protected function createChildren():void {
        if (labelDisplay) return;

        labelDisplay = richText = new RichText();
        addChild(labelDisplay);
        if (label != "") labelDisplay.text = label;
    }


    /* ----------------- */
    /* --- behaviour --- */
    /* ----------------- */

    override protected function commitProperties():void {
        super.commitProperties();
        if (!searchTermsChanged || !labelDisplay) return;

        searchTermsChanged = false;
        if (!_searchTerms) {
            labelDisplay.text = label;
            return;
        }

        var color:uint = getStyle("matchColor") || 0xff0000;
        var attributes:String = " color='#" + color.toString(16) + "'";
        attributes += " fontStyle='" + (getStyle("matchFontStyle") || "normal") + "'";
        attributes += " fontWeight='" + (getStyle("matchFontWeight") || "bold") + "'";
        attributes += " textAlpha='" + (getStyle("matchTextAlpha") || 1) + "'";
        attributes += " textDecoration='" + (getStyle("matchTextDecoration") || "none") + "'";

        var html:String = label.replace(_searchTerms, "<span" + attributes + ">$&</span>");
        richText.textFlow = TextFlowUtil.importFromString(html);
    }

}

}
