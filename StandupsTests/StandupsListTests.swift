import CustomDump
import Dependencies
import XCTest

@testable import Standups

@MainActor
class StandupsListTests: XCTestCase {
    
    func testPersistence() async throws {
        let mainQueue = DispatchQueue.test
        withDependencies {
            $0.dataManager = .mock()
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
            $0.uuid = .incrementing
            
        } operation: {
            let listModel = StandupsListModel()
            
            XCTAssertEqual(listModel.standups.count, 0)
            
            listModel.addStandupButtonTapped()
            listModel.confirmAddStandupButtonTapped()
            XCTAssertEqual(listModel.standups.count, 1)
            
            mainQueue.run()
            
            let nextLaunchListModel = StandupsListModel()
            XCTAssertEqual(nextLaunchListModel.standups.count, 1)
        }
    }
    
    func testEdit() throws {
        let mainQueue = DispatchQueue.test
        try withDependencies {
            $0.dataManager = .mock(
                initialData: try JSONEncoder().encode([Standup.mock])
            )
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        } operation: {
            let listModel = StandupsListModel()
            XCTAssertEqual(listModel.standups.count, 1)
            
            listModel.standupTapped(standup: listModel.standups[0])
            guard case let .some(.detail(detailModel)) = listModel.destination
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(detailModel.standup, listModel.standups[0])
            
            detailModel.editButtonTapped()
            guard case let .some(.edit(editModel)) = detailModel.destination
            else {
                XCTFail()
                return
            }
            
            XCTAssertNoDifference(editModel.standup, detailModel.standup)
            
            editModel.standup.title = "Product"
            detailModel.doneEditingButtonTapped()
            
            XCTAssertNil(detailModel.destination)
            XCTAssertEqual(detailModel.standup.title, "Product")
            
            listModel.destination = nil
            
            XCTAssertEqual(listModel.standups[0].title, "Product")
        }
    }
    
    func testDelete() throws {
        let mainQueue = DispatchQueue.test
        try withDependencies {
            $0.dataManager = .mock(
                initialData: try JSONEncoder().encode([Standup.mock])
            )
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        } operation: {
            let listModel = StandupsListModel()
            XCTAssertEqual(listModel.standups.count, 1)
            
            listModel.standupTapped(standup: .mock)
            guard case let .some(.detail(detailModel)) = listModel.destination
            else {
                XCTFail()
                return
            }
            
            XCTAssertNoDifference(listModel.standups[0], detailModel.standup)
            
            detailModel.deleteButtonTapped()
            
            guard case .some(.alert) = detailModel.destination
            else {
                XCTFail()
                return
            }
            
            detailModel.alertButtonTapped(.confirmDeletion)
            
            XCTAssertNil(listModel.destination)
            
            XCTAssertEqual(listModel.standups.count, 0)
        }
    }
}
