//
//  LoginViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/29/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit
import TwitterKit
import FBSDKLoginKit
import AuthenticationServices
import GoogleSignIn

class LoginViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .authentication

    @IBOutlet weak var loginStackView: UIStackView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var orSeparatorLabel: UILabel!
    @IBOutlet weak var twitterSignInButton: UIButton!
    @IBOutlet weak var facebookSignInButton: UIButton!
    @IBOutlet weak var appleSignInButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!

    @IBOutlet weak var forgotPasswordStackView: UIStackView!
    @IBOutlet weak var forgotPasswordEmailLabel: UILabel!
    @IBOutlet weak var forgotPasswordEmailTextField: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var backToLoginButton: UIButton!

    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var spinnerImageView: UIImageView!

    var isFirstLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))

        orSeparatorLabel.text = "or"
        emailLabel.text = "Email"
        passwordLabel.text = "Password"
        forgotPasswordEmailLabel.text = "Email"

        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: emailTextField.frame.height))
        emailTextField.leftViewMode = .always
        emailTextField.layer.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.cornerRadius = 4
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gumroadGray400]
        )
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: passwordTextField.frame.height))
        passwordTextField.leftViewMode = .always
        passwordTextField.layer.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.cornerRadius = 4
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gumroadGray400]
        )
        forgotPasswordEmailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: forgotPasswordEmailTextField.frame.height))
        forgotPasswordEmailTextField.leftViewMode = .always
        forgotPasswordEmailTextField.layer.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        forgotPasswordEmailTextField.layer.borderWidth = 1
        forgotPasswordEmailTextField.layer.cornerRadius = 4
        forgotPasswordEmailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gumroadGray400]
        )

        loginButton.setTitle("Login", for: .normal)
        loginButton.layer.cornerRadius = 4
        resetPasswordButton.setTitle("Reset password", for: .normal)
        resetPasswordButton.layer.cornerRadius = 4
        backToLoginButton.setTitle("Back to login", for: .normal)

        loginStackView.isHidden = false
        loginStackView.alpha = 1
        forgotPasswordStackView.isHidden = true
        forgotPasswordStackView.alpha = 0

        let forgotPasswordTitle = NSMutableAttributedString(
            string: "Forgot your password?",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor(named: "GumroadLabelColor")!,
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ])
        forgotPasswordButton.setAttributedTitle(forgotPasswordTitle, for: .normal)

        let createAccountTitle = NSMutableAttributedString(
            string: "Don't have an account? Create one.",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor(named: "GumroadLabelColor")!,
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ])
        createAccountButton.setAttributedTitle(createAccountTitle, for: .normal)

        loadingView.isHidden = true

        GRDLoginManager.sharedInstance.setupOAuthObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessful), name: NSNotification.Name(rawValue: GRDLoginManager.sharedInstance.loginSuccessfulNotificationString), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loginError), name: NSNotification.Name(rawValue: GRDLoginManager.sharedInstance.loginErrorNotificationString), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(twitterLoginUnsuccessful), name: NSNotification.Name(rawValue: GRDLoginManager.sharedInstance.twitterLoginUnsuccessfulNotificationString), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appleLoginUnsuccessful), name: NSNotification.Name(rawValue: GRDLoginManager.sharedInstance.appleLoginUnsuccessfulNotificationString), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(googleLoginUnsuccessful), name: NSNotification.Name(rawValue: GRDLoginManager.sharedInstance.googleLoginUnsuccessfulNotificationString), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(facebookAccessTokenChanged), name: NSNotification.Name.AccessTokenDidChange, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstLoad {
            isFirstLoad = false

            let spinnerRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            spinnerRotateAnimation.fromValue = 0.0
            spinnerRotateAnimation.toValue = CGFloat(.pi * 2.0)
            spinnerRotateAnimation.duration = 1
            spinnerRotateAnimation.repeatCount = .greatestFiniteMagnitude
            spinnerRotateAnimation.isRemovedOnCompletion = false
            spinnerImageView.layer.add(spinnerRotateAnimation, forKey: nil)
        }
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @IBAction func loginButtonClicked(_ sender: UIButton) {
        hideKeyboard()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if GRDLoginManager.sharedInstance.isLoginInProgress {
            return
        }
        guard let email = emailTextField?.text.nilIfEmpty else {
            let notificationView = NotificationView(width: emailTextField.frame.width, text: "Please provide a valid email address.", type: .error)
            notificationView.animate(from: view)
            emailTextField.becomeFirstResponder()
            return
        }
        guard let password = passwordTextField?.text.nilIfEmpty else {
            let notificationView = NotificationView(width: emailTextField.frame.width, text: "Please provide a password.", type: .error)
            notificationView.animate(from: view)
            passwordTextField.becomeFirstResponder()
            return
        }
        if !isValidEmail(email) {
            let notificationView = NotificationView(width: emailTextField.frame.width, text: "Please provide a valid email address.", type: .error)
            notificationView.animate(from: view)
            emailTextField.becomeFirstResponder()
            return
        }
        if GRDFileNetworkRequest.shared.isOffline() {
            let notificationView = NotificationView(width: emailTextField.frame.width, text: "You seem to be offline, please check your network connection.", type: .error)
            notificationView.animate(from: view)
            return
        }
        loadingView.isHidden = false
        GRDLoginManager.sharedInstance.attemptLogin(email, password: password)
    }

    @objc func loginSuccessful(notification: NSNotification) {
        loadingView.isHidden = true
        if let accountType = notification.userInfo?["accountType"] as? String {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if accountType == "Twitter",
                let twitterID = GRDLoginManager.sharedInstance.twitterID {
                GRDLoginManager.sharedInstance.logSuccessfulLoginEvent([
                    "login_type": "Twitter",
                    "user_twitter_id": twitterID
                ])
                dismiss(animated: false, completion: nil)
            } else if accountType == "Facebook",
                let facebookID = GRDLoginManager.sharedInstance.facebookID {
                GRDLoginManager.sharedInstance.logSuccessfulLoginEvent([
                    "login_type": "Facebook",
                    "user_facebook_id": facebookID
                ])
                dismiss(animated: false, completion: nil)
            } else if accountType == "Apple",
                let appleUserID = GRDLoginManager.sharedInstance.appleUserID {
                GRDLoginManager.sharedInstance.logSuccessfulLoginEvent([
                    "login_type": "Apple",
                    "apple_user_id": appleUserID
                ])
                dismiss(animated: false, completion: nil)
            } else if accountType == "Google",
                let googleUserID = GRDLoginManager.sharedInstance.googleUserID {
                GRDLoginManager.sharedInstance.logSuccessfulLoginEvent([
                    "login_type": "Google",
                    "google_user_id": googleUserID
                ])
                dismiss(animated: false, completion: nil)
            } else if accountType == "Gumroad",
                let email = emailTextField?.text.nilIfEmpty {
                GRDLoginManager.sharedInstance.setDefaultUserEmailForLogin(email)
                GRDLoginManager.sharedInstance.logSuccessfulLoginEvent([
                    "login_type": "email",
                    "user_email": email
                ])
                dismiss(animated: false, completion: nil)
            }
        }
    }

    @objc func loginError(notification: NSNotification) {
        loadingView.isHidden = true
        if let accountType = notification.userInfo?["accountType"] as? String {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            if accountType == "Twitter" {
                let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Twitter", type: .error)
                notificationView.animate(from: view)
                if let twitterID = GRDLoginManager.sharedInstance.twitterID {
                    GRDLoginManager.sharedInstance.logFailedLoginEvent([
                        "login_type": "Twitter",
                        "user_twitter_id": twitterID
                    ])
                }
            } else if accountType == "Facebook" {
                let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Facebook", type: .error)
                notificationView.animate(from: view)
                if let facebookID = GRDLoginManager.sharedInstance.facebookID {
                    GRDLoginManager.sharedInstance.logFailedLoginEvent([
                        "login_type": "Facebook",
                        "user_facebook_id": facebookID
                    ])
                }
            } else if accountType == "Apple" {
                let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Apple", type: .error)
                notificationView.animate(from: view)
                if let appleUserID = GRDLoginManager.sharedInstance.appleUserID {
                    GRDLoginManager.sharedInstance.logFailedLoginEvent([
                        "login_type": "Apple",
                        "apple_user_id": appleUserID
                    ])
                }
            } else if accountType == "Google" {
                let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Google", type: .error)
                notificationView.animate(from: view)
                if let googleUserID = GRDLoginManager.sharedInstance.googleUserID {
                    GRDLoginManager.sharedInstance.logFailedLoginEvent([
                        "login_type": "Google",
                        "google_user_id": googleUserID
                    ])
                }
            } else if accountType == "Gumroad" {
                let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in. Try again.", type: .error)
                notificationView.animate(from: view)
                GRDLoginManager.sharedInstance.logFailedLoginEvent([
                    "login_type": "email",
                    "user_email": emailTextField.text ?? ""
                ])
            }
        }
    }

    @IBAction func forgotPasswordClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        view.frame.origin.y = 0
        UIView.animate(withDuration: 0.5) {
            self.loginStackView.isHidden = true
            self.loginStackView.alpha = 0
            self.loginStackView.layoutIfNeeded()
            self.forgotPasswordStackView.isHidden = false
            self.forgotPasswordStackView.alpha = 1
            self.forgotPasswordStackView.layoutIfNeeded()
            self.forgotPasswordEmailTextField.text = self.emailTextField.text
            self.forgotPasswordEmailTextField.becomeFirstResponder()
        }
    }

    @IBAction func createAccountClicked(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.hideKeyboard()
        let webVC = WebViewController()
        let navController = UINavigationController(rootViewController: webVC)
        webVC.loadURL(URL(string: "https://gumroad.com/signup")!)
        webVC.onCurrentURLChange = { url in
            if url == URL(string: "https://gumroad.com/dashboard")! {
                logEvent("account_created")
                let dataStore = WKWebsiteDataStore.default()
                dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                    records.forEach { record in
                        dataStore.removeData(
                            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                            for: [record],
                            completionHandler: {}
                        )
                    }
                }
                self.dismiss(animated: true) {
                    let notificationView = NotificationView(width: self.emailTextField.frame.width, text: "Your account has been created. Please login!", type: .success)
                    notificationView.animate(from: self.view)
                }
            } else if url == URL(string: "https://gumroad.com/signup")! {
                // Hide header login link and all social login buttons to appease Apple App Review. We can revert this once this ticket is fixed: https://www.notion.so/gumroad/Support-Sign-in-with-Apple-on-web-2d87e2bad5b14680a5ae9d47bceaee7e?pvs=4
                let javascript = """
                    const header = document.querySelector('header');
                    if (header) {
                        const children = header.querySelectorAll(':scope > *');
                        children.forEach(child => {
                            if (!child.classList.contains('logo-full')) {
                                child.remove();
                            }
                        });
                    }

                    const socialLoginsSection = document.querySelector('div > form > section.paragraphs');
                    socialLoginsSection.remove();

                    const dividerDiv = document.querySelector('div[role="separator"]');
                    dividerDiv.remove();
                """.replacingOccurrences(of: "\n", with: "")
                webVC.webView.evaluateJavaScript(javascript, completionHandler: nil)
            }
        }
        logEvent("create_account_clicked")
        self.present(navController, animated: true, completion: nil)
    }

    @objc func twitterLoginUnsuccessful(notification: NSNotification) {
        loadingView.isHidden = true
        let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Twitter", type: .error)
        notificationView.animate(from: view)
    }

    @objc func appleLoginUnsuccessful(notification: NSNotification) {
        loadingView.isHidden = true
        let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Apple", type: .error)
        notificationView.animate(from: view)
    }

    @objc func googleLoginUnsuccessful(notification: NSNotification) {
        loadingView.isHidden = true
        let notificationView = NotificationView(width: emailTextField.frame.width, text: "Could not log in with Google", type: .error)
        notificationView.animate(from: view)
    }

    @IBAction func facebookButtonClicked(_ sender: Any) {
        hideKeyboard()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        LoginManager().logIn(permissions: ["email"], from: presentingViewController, handler: { [weak self] (result, error) -> Void in
            guard let self = self else { return }
            if error != nil || result?.isCancelled == true {
                let notificationView = NotificationView(width: self.emailTextField.frame.width, text: "Could not log in with Facebook", type: .error)
                notificationView.animate(from: self.view)
            }
            // we don't need to do anything in the successful case, because the facebookAccessTokenChanged listener already handles logging in
        })
    }

    @objc func facebookAccessTokenChanged(notification: NSNotification) {
        guard
            AccessToken.current != nil,
            let userID = AccessToken.current?.userID,
            let token = AccessToken.current?.tokenString
            else { return }
        GRDLoginManager.sharedInstance.setCurrentFacebookID(userID)
        GRDLoginManager.sharedInstance.attemptFacebookLogin(token)
    }

    @IBAction func twitterButtonClicked(_ sender: Any) {
        hideKeyboard()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        TWTRTwitter.sharedInstance().logIn(with: self) { (session: TWTRSession?, error: Error?) -> Void in
            guard error != nil else {
                // no errors - log in the user if successful
                guard let twitterSession = session, twitterSession.authToken.count > 0 else { return }
                GRDLoginManager.sharedInstance.setCurrentTwitterID(twitterSession.userID)
                GRDLoginManager.sharedInstance.attemptTwitterLogin(twitterSession.authToken)
                return
            }
            GRDLoginManager.sharedInstance.postNotificationForTwitterLoginUnsuccessful()
        }
    }

    @IBAction func appleButtonClicked(_ sender: Any) {
        hideKeyboard()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    @IBAction func googleButtonClicked(_ sender: Any) {
        hideKeyboard()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error != nil else {
                signInResult?.user.refreshTokensIfNeeded { user, error in
                    guard error == nil else { return }
                    guard let user = user else { return }

                    guard let idToken = user.idToken?.tokenString else { return }
                    print("clientID: \(user.configuration.clientID)")
                    print("idToken: \(idToken)")
                    print("accessToken: \(user.accessToken.tokenString)")

                    GRDLoginManager.sharedInstance.setCurrentGoogleUserID(user.userID ?? "")
                    GRDLoginManager.sharedInstance.attemptGoogleLogin(idToken)
                }
                return
            }
            GRDLoginManager.sharedInstance.postNotificationForGoogleLoginUnsuccessful()
        }
    }

    @IBAction func resetPasswordButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let email = forgotPasswordEmailTextField?.text.nilIfEmpty else {
            let notificationView = NotificationView(width: forgotPasswordEmailTextField.frame.width, text: "Please provide a valid email address.", type: .error)
            notificationView.animate(from: view)
            forgotPasswordEmailTextField.becomeFirstResponder()
            return
        }
        if !isValidEmail(email) {
            let notificationView = NotificationView(width: forgotPasswordEmailTextField.frame.width, text: "Please provide a valid email address.", type: .error)
            notificationView.animate(from: view)
            forgotPasswordEmailTextField.becomeFirstResponder()
            return
        }
        if GRDFileNetworkRequest.shared.isOffline() {
            let notificationView = NotificationView(width: emailTextField.frame.width, text: "You seem to be offline, please check your network connection.", type: .error)
            notificationView.animate(from: view)
            return
        }

        hideKeyboard()
        loadingView.isHidden = false
        _ = GRDNetworkRequest.shared.resetPassword(
            email,
            successBlock: { [weak self] () -> Void in
                guard let self = self else { return }
                self.loadingView.isHidden = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                let notificationView = NotificationView(width: self.forgotPasswordEmailTextField.frame.width, text: "Sent!", type: .success)
                notificationView.animate(from: self.view)
                return
            }, failureBlock: { [weak self] (error) -> Void in
                guard let self = self else { return }
                self.loadingView.isHidden = true
                let notificationView = NotificationView(width: self.forgotPasswordEmailTextField.frame.width, text: "Something went wrong.", type: .error)
                notificationView.animate(from: self.view)
                self.forgotPasswordEmailTextField.becomeFirstResponder()
                return
        })
    }

    @IBAction func backToLoginClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.5) {
            self.loginStackView.isHidden = false
            self.loginStackView.alpha = 1
            self.loginStackView.layoutIfNeeded()
            self.forgotPasswordStackView.isHidden = true
            self.forgotPasswordStackView.alpha = 0
            self.forgotPasswordStackView.layoutIfNeeded()
            self.emailTextField.text = self.forgotPasswordEmailTextField.text
            self.emailTextField.becomeFirstResponder()
        }
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            if let authorizationCode = appleIDCredential.authorizationCode, let authCode = String(data: authorizationCode, encoding: .utf8) {
                GRDLoginManager.sharedInstance.setCurrentAppleUserID(appleIDCredential.user)
                GRDLoginManager.sharedInstance.attemptAppleLogin(authCode)
            } else {
                GRDLoginManager.sharedInstance.postNotificationForAppleLoginUnsuccessful()
            }
        default:
            break
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
       return self.view.window!
    }
}
