/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <TargetConditionals.h>
#if !TARGET_OS_OSX && !TARGET_OS_TV


#import "FIRMultiFactorResolver.h"

#import "FIRAdditionalUserInfo.h"
#import "FIRAuthBackend+MultiFactor.h"
#import "FIRAuthDataResult_Internal.h"
#import "FIRAuthProtoFinalizeMfaPhoneRequestInfo.h"
#import "FIRAuth_Internal.h"
#import "FIRFinalizeMfaSignInRequest.h"
#import "FIRMultiFactorResolver+Internal.h"
#import "FIRMultiFactorSession+Internal.h"

#if TARGET_OS_IOS
#import "FIRPhoneAuthCredential_Internal.h"
#import "FIRPhoneMultiFactorAssertion+Internal.h"
#import "FIRPhoneMultiFactorAssertion.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation FIRMultiFactorResolver

- (instancetype)initWithMfaPendingCredential:(NSString *_Nullable)mfaPendingCredential
                                       hints:(NSArray<FIRMultiFactorInfo *> *)hints {
  self = [super init];
  if (self) {
    _mfaPendingCredential = mfaPendingCredential;
    _hints = hints;
    _auth = [FIRAuth auth];
    _session = [[FIRMultiFactorSession alloc] init];
    _session.mfaPendingCredential = mfaPendingCredential;
  }
  return self;
}

- (void)resolveSignInWithAssertion:(nonnull FIRMultiFactorAssertion *)assertion
                        completion:(nullable FIRAuthDataResultCallback)completion {
#if TARGET_OS_IOS
  FIRPhoneMultiFactorAssertion *phoneAssertion = (FIRPhoneMultiFactorAssertion *)assertion;
  FIRAuthProtoFinalizeMfaPhoneRequestInfo *finalizeMfaPhoneRequestInfo =
      [[FIRAuthProtoFinalizeMfaPhoneRequestInfo alloc]
       initWithSessionInfo:phoneAssertion.authCredential.verificationID
       verificationCode:phoneAssertion.authCredential.verificationCode];
  FIRFinalizeMfaSignInRequest *request =
  [[FIRFinalizeMfaSignInRequest alloc] initWithMfaProvider:phoneAssertion.factorID
                                      mfaPendingCredential:self.mfaPendingCredential
                                          verificationInfo:finalizeMfaPhoneRequestInfo
                                      requestConfiguration:self.auth.requestConfiguration];
  [FIRAuthBackend finalizeMultiFactorSignIn:request
                                   callback:^(FIRFinalizeMfaSignInResponse * _Nullable response,
                                              NSError * _Nullable error) {
   if (error) {
     if (completion) {
       completion(nil, error);
     }
   } else {
     [FIRAuth.auth completeSignInWithAccessToken:response.idToken
                       accessTokenExpirationDate:nil
                            refreshToken:response.refreshToken
                               anonymous:NO
                                callback:^(FIRUser *_Nullable user, NSError *_Nullable error) {
      FIRAuthDataResult* result =
          [[FIRAuthDataResult alloc] initWithUser:user additionalUserInfo:nil];
      FIRAuthDataResultCallback decoratedCallback =
          [FIRAuth.auth signInFlowAuthDataResultCallbackByDecoratingCallback:completion];
      decoratedCallback(result, error);
    }];
   }
 }];
#endif
}

@end

NS_ASSUME_NONNULL_END

#endif
