//
//  CerSelecteViewController.swift
//  PushMeGod
//
//  Created by ding_qili on 17/1/7.
//  Copyright © 2017年 ding_qili. All rights reserved.
//

import Cocoa

class CerInfo:NSObject{
    dynamic var name:String = ""
    dynamic var path:String = ""
}

class CerSelecteViewController: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var arraryController: NSArrayController!
    
    dynamic var cers:NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(forDraggedTypes: [NSFilenamesPboardType])
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false);
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.move, forLocal: false);
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.doubleAction = #selector(onDoubleAction)
        
        if let cers =  CerStoreUtil.getAllCerInfo() {
            arraryController.add(contentsOf: cers)
        }
        
    }
    
    func addCerInfo(info:CerInfo){
        arraryController.addObject(info)
        CerStoreUtil.addCer(info: info)
    }
    
    func onDoubleAction(){
        let clickRow =  self.tableView.clickedRow;
        if let cerInfo = cers.object(at: clickRow) as? CerInfo {
            self.performSegue(withIdentifier: "pushViewController", sender: cerInfo.path)
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let pushViewController  = segue.destinationController as? PushViewController {
            pushViewController.path = sender as? String
        }
    }
}




extension CerSelecteViewController:NSTableViewDelegate {
    
}

extension CerSelecteViewController:NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet){
        
    }
    
    
    /* Dragging Source Support - Optional. Implement this method to know when the dragging session has ended. This delegate method can be used to know when the dragging source operation ended at a specific location, such as the trash (by checking for an operation of NSDragOperationDelete).
     */
    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation){
    
    }
    
    
    /* Dragging Destination Support - Required for multi-image dragging. Implement this method to allow the table to update dragging items as they are dragged over the view. Typically this will involve calling [draggingInfo enumerateDraggingItemsWithOptions:forView:classes:searchOptions:usingBlock:] and setting the draggingItem's imageComponentsProvider to a proper image based on the content. For View Based TableViews, one can use NSTableCellView's -draggingImageComponents. For cell based TableViews, use NSCell's draggingImageComponentsWithFrame:inView:.
     */
    public func tableView(_ tableView: NSTableView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo){
    
    }
    
    
    /* Dragging Source Support - Optional for single-image dragging. Implement this method to support single-image dragging. Use the more modern tableView:pasteboardWriterForRow: to support multi-image dragging. This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  'rowIndexes' contains the row indexes that will be participating in the drag.
     */
    public func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool{
        return true
    }
    
    
    /* Dragging Destination Support - This method is used by NSTableView to determine a valid drop target. Based on the mouse position, the table view will suggest a proposed drop 'row' and 'dropOperation'. This method must return a value that indicates which NSDragOperation the data source will perform. The data source may "re-target" a drop, if desired, by calling setDropRow:dropOperation: and returning something other than NSDragOperationNone. One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
     */
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation{
        return NSDragOperation.move
    }
    
    
    /* Dragging Destination Support - This method is called when the mouse is released over an NSTableView that previously decided to allow a drop via the validateDrop method. The data source should incorporate the data from the dragging pasteboard at this time. 'row' and 'dropOperation' contain the values previously set in the validateDrop: method.
     */
    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool{
        if let urls = info.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? [String] {
            let url = URL(fileURLWithPath: urls.first ?? "")
            if url.lastPathComponent.hasSuffix(".cer"){
                let info = CerInfo()
                info.name = url.lastPathComponent
                info.path = url.path
                self.addCerInfo(info: info)
                return true
            }
        }
        return false
    }
    
    
    /* Dragging Destination Support - NSTableView data source objects can support file promised drags by adding NSFilesPromisePboardType to the pasteboard in tableView:writeRowsWithIndexes:toPasteboard:.  NSTableView implements -namesOfPromisedFilesDroppedAtDestination: to return the results of this data source method.  This method should returns an array of filenames for the created files (filenames only, not full paths).  The URL represents the drop location.  For more information on file promise dragging, see documentation on the NSDraggingSource protocol and -namesOfPromisedFilesDroppedAtDestination:.
     */
    func tableView(_ tableView: NSTableView, namesOfPromisedFilesDroppedAtDestination dropDestination: URL, forDraggedRowsWith indexSet: IndexSet) -> [String]{
        return []
    }

}


class CerStoreUtil{
    private static let fileName = "/cerFile.plist";
    static var filePath:String?{
        let dirs =  NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true);
        guard let ducumentDir = dirs.first else{
            return nil
        }
        return ducumentDir.appending(fileName)
    }
    
    static func addCer(info:CerInfo) ->Bool{
        var browseIds = getAllCerPath() ?? []
        if let index = browseIds.index(of: info.path) {
            browseIds.remove(at: index)
        }
        browseIds.insert(info.path, at: 0)
        guard let filePath = self.filePath else {
            return false
        }
        let browseIdsArray = browseIds as? NSArray;
        browseIdsArray?.write(toFile: filePath, atomically: true)
        return true
    }
    
    static func getAllCerPath() ->[String]?{
        guard let filePath = self.filePath else {
            return []
        }
        let array =  NSArray(contentsOfFile: filePath);
        return array as? [String];
    }
    
    static func getAllCerInfo() ->[CerInfo]?{
        guard let filePath = self.filePath else {
            return []
        }
        let array =  NSArray(contentsOfFile: filePath);
        if let path =  array as? [String] {
            let cerList =  path.map({ (path) -> CerInfo in
                let cerInfo = CerInfo()
                cerInfo.path = path
                cerInfo.name = URL(fileURLWithPath: path).lastPathComponent
                return cerInfo
            })
            return cerList
        }
        return []
    }
    
}
