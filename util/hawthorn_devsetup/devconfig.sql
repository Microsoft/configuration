
use edxapp;

-- Adding a course mode

INSERT INTO `course_modes_coursemode` VALUES (1,'course-v1:Microsoft+MS101+course','honor','test certificate',0,'usd',NULL,NULL,'',NULL,NULL,0,NULL);

-- Enable Certificates

INSERT INTO `certificates_certificategenerationconfiguration` VALUES (1,'2018-09-13 22:49:19.910990',1,NULL);

INSERT INTO `certificates_certificategenerationcoursesetting` VALUES (1,'2018-09-13 23:31:05.469032','2018-09-13 23:31:05.471333','course-v1:Microsoft+MS101+course',0,1,NULL);

UPDATE `certificates_certificatehtmlviewconfiguration` SET  enabled = 1; 

-- Creating multi site

INSERT INTO `django_site` VALUES (2,'localhost:18010','cms-cleanoxahaw'),(3,'courses.dev.oxa.microsoft.com','courses-dev-oxa'),(4,'preview.dev.oxa.microsoft.com','preview-dev');


INSERT INTO `site_configuration_siteconfiguration` VALUES (1,'{\"course_org_filter\":\"Microsoft\",\"ENABLE_AZURE_MEDIA_SERVICES_XBLOCK\":true,\"ENABLE_THIRD_PARTY_AUTH\":true,\"LMS_BASE\":\"localhost\",\"PREVIEW_LMS_BASE\":\"localhost\",\"SITE_NAME\":\"localhost\",\"LMS_ROOT_URL\":\"http:localhost/\",\"REGISTRATION_EMAIL_PATTERNS_ALLOWED\":[\"(?i)^(?:(?!(microsoft.com)).)+$\"],\"external_login_api\":\"https://api.bvt.mlxma.microsoft.com/api/v2.0/Authentication/ExternalLogin?Provider=RPS&PartnerName=OXA&RedirectUri=\",\"ENABLE_COMBINED_LOGIN_REGISTRATION\":true,\"ENABLE_COMBINED_LOGIN_REGISTRATION_FOOTER\":true,\"ENABLE_MSA_MIGRATION\":true,\"ENFORCE_PASSWORD_POLICY\":false}',1,1),(2,'{\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_AZURE_MEDIA_SERVICES_XBLOCK\":true}',2,1),(3,'{\"course_org_filter\":\"ELMS\",\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"ENFORCE_PASSWORD_POLICY\":false,\"LMS_ROOT_URL\":\"https://courses.dev.oxa.microsoft.com\",\"SITE_NAME\":\"courses.dev.oxa.microsoft.com\",\"course_email_template_name\":\"courses.template\",\"RESTRICT_COURSES_API\":true,\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\",\"^api/courses/v1/courses\",\"^api/grades/v1/course_grade.*$\",\"^oauth2/access_token\",\"^api/enrollment/v1/enrollment\",\"^api/mobile/v0.5/my_user_info.*$\",\"^api/mobile/v0.5/users.*$\",\"^api/grades/v0/course_grade.*$\"],\"REGISTRATION_EXTRA_FIELDS\":{\"city\":\"hidden\",\"country\":\"hidden\",\"disclosure_notice\":\"optional\",\"gender\":\"hidden\",\"goals\":\"hidden\",\"honor_code\":\"hidden\",\"language\":\"hidden\",\"level_of_education\":\"hidden\",\"mailing_address\":\"hidden\",\"terms_of_service\":\"required\",\"year_of_birth\":\"hidden\"}}',3,1),(4,'{\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY_AUTH\":true}',4,1);

