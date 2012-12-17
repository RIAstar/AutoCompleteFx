##AutoCompleteFx: A Flex/Spark AutoComplete implementation

AutoCompleteFx is an AutoComplete component for Flex 4+ and the Spark architecture. It is based on [DropDownListBase](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/supportClasses/DropDownListBase.html) and provides functionalities that neither [DropDownList](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/DropDownList.html) or [ComboBox](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/ComboBox.html) can deliver.

AutoCompleteFx works exactly as you would expect from a List, meaning the [selectedIndex](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/supportClasses/ListBase.html#selectedIndex), [selectedIndices](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/List.html#selectedIndices), [selectedItem](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/supportClasses/ListBase.html#selectedItem) and [selectedItems](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/List.html#selectedItems) are all properly updated when the user selects items from the list. Incidentally one can also (two-way) bind on said properties.  

For consistency with the Spark theme, AutoCompleteFx' default skin looks exactly like a regular ComboBox', except a second `List` was added to optionally display the selected items.

###Features
 - single/multiple select
 - matches multiple words in the search query
 - fully compatible with other List-like components
 - highlight matched text + styles for the highlighted section
 - selection list can be defined outside the component (will override the one in the default skin)
 - GridItemRenderer implementation
 - hide/show the `openButton` that is present by default in DropDownListBase

###Planned features
 - possibility to set search rules (match all, match any, ...)
 - suggestions ordered by scoring algorithm
 - optionally sort selection list in the same order as the `dataProvider` (default = selection order)
 - optional automatic creation of items when submitting items that don't exist in the `dataProvider`
 - ...

