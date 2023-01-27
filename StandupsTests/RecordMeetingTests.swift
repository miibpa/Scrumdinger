import Clocks
import Dependencies
import XCTest

@testable import Standups

class RecordMeetingTests: XCTestCase {
    func testTimer() async {
        await withDependencies {
            $0.continuousClock = ImmediateClock()
            $0.speechClient.requestAuthorization = { .denied }
        } operation: { @MainActor in
            var standup = Standup.mock
            standup.duration = .seconds(6)
            let recordModel = RecordMeetingModel(standup: standup)
            let expectation = self.expectation(description: "onMeetingFinished")
            recordModel.onMeetingFinished = { _ in expectation.fulfill() }
            
            await recordModel.task()
            self.wait(for: [expectation], timeout: 0)
            XCTAssertEqual(recordModel.secondsElapsed, 6)
            XCTAssertEqual(recordModel.dismiss, true)
        }
    }
    
    func testTimerStops() async {
        let clock = TestClock()
        let recognitionTask = AsyncThrowingStream<SpeechRecognitionResult, Error>.streamWithContinuation()
        await withDependencies {
            $0.continuousClock = clock
            $0.speechClient.requestAuthorization = { .authorized }
            $0.speechClient.startTask = { _ in recognitionTask.stream }
        } operation: { @MainActor in
            var standup = Standup.mock
            standup.duration = .seconds(6)
            let recordModel = RecordMeetingModel(standup: standup)
            
            await recordModel.task()
            await clock.advance(by: .seconds(1))
            recordModel.endMeetingButtonTapped()
            await clock.advance(by: .seconds(1))
            
            guard case .some(.alert) = recordModel.destination
            else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(recordModel.secondsElapsed, 1)
        }
    }
}
