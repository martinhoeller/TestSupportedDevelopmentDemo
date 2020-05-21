import XCTest
@testable import TestSupportedDevelopmentDemo

class LogoutUseCaseTests: XCTestCase {
    var sut: LogoutUseCase!
    var mockLogoutConfirmationPresenter: MockLogoutConfirmationPresenter!
    var mockSyncStatusChecker: MockSyncStatusChecker!
    var mockDataSyncer: MockDataSyncer!
    var mockLogoutHandler: MockLogoutHandler!

    override func setUp() {
        super.setUp()

        mockLogoutConfirmationPresenter = MockLogoutConfirmationPresenter()
        mockSyncStatusChecker = MockSyncStatusChecker()
        mockDataSyncer =  MockDataSyncer()
        mockLogoutHandler = MockLogoutHandler()
        sut = LogoutUseCase(logoutConfirmationPresenter: mockLogoutConfirmationPresenter,
                            syncStatusChecker: mockSyncStatusChecker,
                            dataSyncer: mockDataSyncer,
                            logoutHandler: mockLogoutHandler)
    }

    func test_logout_showsConfirmationDialog() {
        sut.logout { _, _ in }
        XCTAssertTrue(mockLogoutConfirmationPresenter.didShowConfirmationDialog)
    }

    func test_logout_userCancelled_returnsUserCancelledError() {
        mockLogoutConfirmationPresenter.stubShouldLogOut = false
        sut.logout { _, error in
            XCTAssertEqual(.userCancelled, error)
        }
    }

    func test_logout_checksSyncStatus() {
        sut.logout { _, _ in }
        XCTAssertTrue(mockSyncStatusChecker.didCheckIfDataIsSynced)
    }

    func test_logout_dataNotInSync_syncsData() {
        mockSyncStatusChecker.stubDataIsSynced = false
        sut.logout { _, _ in }
        XCTAssertTrue(mockDataSyncer.didSyncData)
    }

    func test_logout_syncFailed_returnsSyncFailedError() {
        mockSyncStatusChecker.stubDataIsSynced = false
        mockDataSyncer.stubSuccess = false
        sut.logout { _, error in
            XCTAssertEqual(.syncFailed, error)
        }
    }
    
    func test_logout_syncFailed_showsErrorMessage() {
        mockSyncStatusChecker.stubDataIsSynced = false
        mockDataSyncer.stubSuccess = false
        sut.logout { _, _ in }
        XCTAssertTrue(mockLogoutConfirmationPresenter.didShowLogoutError)
    }

    func test_logout_dataInSync_logsOut() {
        sut.logout { _, _ in }
        XCTAssertTrue(mockLogoutHandler.didLogOut)
    }

    func test_logout_syncSuccessful_logsOut() {
        mockSyncStatusChecker.stubDataIsSynced = false
        sut.logout { _, _ in }
        XCTAssertTrue(mockLogoutHandler.didLogOut)
    }

    func test_logout_logoutFails_returnsLogoutFailedError() {
        mockLogoutHandler.stubSuccess = false
        sut.logout { _, error in
            XCTAssertEqual(.logoutFailed, error)
        }
    }

    func test_logout_logoutFailed_showsErrorMessage() {
        mockLogoutHandler.stubSuccess = false
        sut.logout { _, _ in }
        XCTAssertTrue(mockLogoutConfirmationPresenter.didShowLogoutError)
    }

    func test_logout_successfulLogout_doesntShowErrorMessage() {
        sut.logout { _, _ in }
        XCTAssertFalse(mockLogoutConfirmationPresenter.didShowLogoutError)
    }

    func test_logout_successfulLogout_doesntReturnError() {
        sut.logout { _, error in
            XCTAssertNil(error)
        }
    }
}

class MockLogoutConfirmationPresenter: LogoutConfirmationPresenting {
    var didShowConfirmationDialog = false
    var stubShouldLogOut = true
    func showConfirmationDialog(completion: (Bool) -> Void) {
        didShowConfirmationDialog = true
        completion(stubShouldLogOut)
    }

    var didShowLogoutError = false
    func showLogoutError() {
        didShowLogoutError = true
    }
}

class MockSyncStatusChecker: SyncStatusChecking {
    var didCheckIfDataIsSynced = false
    var stubDataIsSynced = true
    func checkIfDataIsSynced(completion: (Bool) -> Void) {
        didCheckIfDataIsSynced = true
        completion(stubDataIsSynced)
    }
}

final class MockDataSyncer: DataSyncing {
    var didSyncData = false
    var stubSuccess = true
    func syncData(completion: (Bool) -> Void) {
        didSyncData = true
        completion(stubSuccess)
    }
}

class MockLogoutHandler: LogoutHandling {
    var didLogOut = false
    var stubSuccess = true
    func logout(completion: (Bool) -> Void) {
        didLogOut = true
        completion(stubSuccess)
    }
}
