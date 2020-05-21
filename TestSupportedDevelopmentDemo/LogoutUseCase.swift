import Foundation

class LogoutUseCase {
    enum LogoutError: Error {
        case userCancelled
        case syncFailed
        case logoutFailed
    }

    private let logoutConfirmationPresenter: LogoutConfirmationPresenting
    private let syncStatusChecker: SyncStatusChecking
    private let dataSyncer: DataSyncing
    private let logoutHandler: LogoutHandling

    init(logoutConfirmationPresenter: LogoutConfirmationPresenting,
         syncStatusChecker: SyncStatusChecking,
         dataSyncer: DataSyncing,
         logoutHandler: LogoutHandling) {
        self.logoutConfirmationPresenter = logoutConfirmationPresenter
        self.syncStatusChecker = syncStatusChecker
        self.dataSyncer = dataSyncer
        self.logoutHandler = logoutHandler
    }

    func logout(completion: @escaping (Bool, LogoutError?) -> Void) {
        logoutConfirmationPresenter.showConfirmationDialog { shouldLogOut in
            if !shouldLogOut {
                completion(false, .userCancelled)
                return
            }

            self.syncStatusChecker.checkIfDataIsSynced { inSync in
                if inSync {
                    self.doLogout(completion: completion)
                } else {
                    dataSyncer.syncData { success in
                        if success {
                            self.doLogout(completion: completion)
                        } else {
                            // sync failed: exit with error
                            self.finish(error: LogoutError.syncFailed, completion: completion)
                        }
                    }
                }
            }
        }
    }

    private func doLogout(completion: @escaping (Bool, LogoutError?) -> Void) {
        logoutHandler.logout { success in
            if success {
                self.finish(error: nil, completion: completion)
            } else {
                self.finish(error: LogoutError.logoutFailed, completion: completion)
            }
        }
    }

    private func finish(error: LogoutError?, completion: @escaping (Bool, LogoutError?) -> Void) {
        let success = (error == nil)

        if !success {
            logoutConfirmationPresenter.showLogoutError()
        }

        completion(success, error)
    }
}

protocol LogoutConfirmationPresenting {
    func showConfirmationDialog(completion: (Bool) -> Void)
    func showLogoutError()
}

protocol SyncStatusChecking {
    func checkIfDataIsSynced(completion: (Bool) -> Void)
}

protocol DataSyncing {
    func syncData(completion: (Bool) -> Void)
}

protocol LogoutHandling {
    func logout(completion: (Bool) -> Void)
}

protocol UserDataDeleting {
    func deleteUserData()
}
