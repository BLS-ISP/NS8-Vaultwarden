<!--
  Copyright (C) 2024 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row v-if="configured && host">
      <cv-column>
        <NsInlineNotification
          kind="info"
          :title="$t('settings.urls_info_title')"
          :description="
            admin_enabled
              ? $t('settings.urls_info_description_with_admin', {
                  host: host,
                })
              : $t('settings.urls_info_description', {
                  host: host,
                })
          "
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row v-if="smarthost_enabled">
      <cv-column>
        <NsInlineNotification
          kind="info"
          :title="$t('settings.smarthost_active_title')"
          :description="
            $t('settings.smarthost_active_description', {
              host: smarthost_host,
            })
          "
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.host')"
              v-model.trim="host"
              placeholder="vault.example.org"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.host"
              ref="host"
            ></cv-text-input>
            <NsToggle
              :label="$t('settings.lets_encrypt')"
              value="lets_encrypt"
              :form-item="true"
              v-model="lets_encrypt"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="lets_encrypt"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <NsToggle
              :label="$t('settings.http2https')"
              value="http2https"
              :form-item="true"
              v-model="http2https"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="http2https"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>

            <NsToggle
              :label="$t('settings.admin_enabled')"
              value="admin_enabled"
              :form-item="true"
              v-model="admin_enabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="admin_enabled"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <cv-text-input
              v-if="admin_enabled || ldap_domain"
              :label="$t('settings.admin_password')"
              type="password"
              v-model.trim="admin_password"
              :helper-text="$t('settings.admin_password_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.admin_password"
              ref="admin_password"
            ></cv-text-input>

            <NsToggle
              :label="$t('settings.signups_allowed')"
              value="signups_allowed"
              :form-item="true"
              v-model="signups_allowed"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="signups_allowed"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <NsToggle
              :label="$t('settings.signups_verify')"
              value="signups_verify"
              :form-item="true"
              v-model="signups_verify"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="signups_verify"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <cv-text-input
              :label="$t('settings.signups_domains_whitelist')"
              v-model.trim="signups_domains_whitelist"
              placeholder="example.org,company.de"
              :helper-text="$t('settings.signups_domains_whitelist_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.signups_domains_whitelist"
              ref="signups_domains_whitelist"
            ></cv-text-input>
            <NsToggle
              :label="$t('settings.invitations_allowed')"
              value="invitations_allowed"
              :form-item="true"
              v-model="invitations_allowed"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="invitations_allowed"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>

            <NsComboBox
              v-model.trim="ldap_domain"
              :autoFilter="true"
              :autoHighlight="true"
              :title="$t('settings.ldap_domain')"
              :label="$t('settings.choose_ldap_domain')"
              :options="ldap_domain_list"
              :clearFilterLabel="$t('settings.clear_selection')"
              :acceptUserInput="false"
              :showItemType="true"
              :invalid-message="error.ldap_domain"
              :disabled="loading.getConfiguration || loading.configureModule"
              tooltipAlignment="start"
              tooltipDirection="top"
              ref="ldap_domain"
            >
              <template slot="tooltip">
                {{ $t("settings.choose_the_ldap_domain_to_invite_users") }}
              </template>
            </NsComboBox>
            <cv-text-input
              v-if="ldap_domain"
              :label="$t('settings.ldap_sync_interval')"
              type="number"
              v-model.trim="ldap_sync_interval"
              placeholder="3600"
              :helper-text="$t('settings.ldap_sync_interval_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.ldap_sync_interval"
              ref="ldap_sync_interval"
            ></cv-text-input>
            <cv-text-input
              v-if="ldap_domain"
              :label="$t('settings.ldap_search_filter')"
              v-model.trim="ldap_search_filter"
              placeholder="(&(objectClass=inetOrgPerson)(mail=*))"
              :helper-text="$t('settings.ldap_search_filter_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.ldap_search_filter"
              ref="ldap_search_filter"
            ></cv-text-input>

            <cv-accordion ref="accordion" class="mg-bottom-lg">
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{
                  $t("settings.advanced_settings")
                }}</template>
                <template slot="content">
                  <NsToggle
                    :label="$t('settings.sends_allowed')"
                    value="sends_allowed"
                    :form-item="true"
                    v-model="sends_allowed"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    ref="sends_allowed"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <NsToggle
                    :label="$t('settings.emergency_access_allowed')"
                    value="emergency_access_allowed"
                    :form-item="true"
                    v-model="emergency_access_allowed"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    ref="emergency_access_allowed"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <NsToggle
                    :label="$t('settings.org_events_enabled')"
                    value="org_events_enabled"
                    :form-item="true"
                    v-model="org_events_enabled"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    ref="org_events_enabled"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <NsToggle
                    :label="$t('settings.show_password_hint')"
                    value="show_password_hint"
                    :form-item="true"
                    v-model="show_password_hint"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    ref="show_password_hint"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <cv-text-input
                    :label="$t('settings.smtp_from')"
                    v-model.trim="smtp_from"
                    placeholder="vaultwarden@example.org"
                    :helper-text="$t('settings.smtp_from_helper')"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    :invalid-message="error.smtp_from"
                    ref="smtp_from"
                  ></cv-text-input>
                  <NsToggle
                    :label="$t('settings.push_enabled')"
                    value="push_enabled"
                    :form-item="true"
                    v-model="push_enabled"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    ref="push_enabled"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <cv-text-input
                    v-if="push_enabled"
                    :label="$t('settings.push_installation_id')"
                    v-model.trim="push_installation_id"
                    :helper-text="$t('settings.push_installation_helper')"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    :invalid-message="error.push_installation_id"
                    ref="push_installation_id"
                  ></cv-text-input>
                  <cv-text-input
                    v-if="push_enabled"
                    :label="$t('settings.push_installation_key')"
                    type="password"
                    v-model.trim="push_installation_key"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    :invalid-message="error.push_installation_key"
                    ref="push_installation_key"
                  ></cv-text-input>
                  <cv-text-input
                    v-if="push_enabled"
                    :label="$t('settings.push_relay_uri')"
                    v-model.trim="push_relay_uri"
                    placeholder="https://push.bitwarden.com"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    :invalid-message="error.push_relay_uri"
                    ref="push_relay_uri"
                  ></cv-text-input>
                </template>
              </cv-accordion-item>
            </cv-accordion>

            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      toggleAccordion: [false],
      configured: false,
      host: "",
      lets_encrypt: false,
      http2https: true,
      admin_enabled: true,
      admin_password: "",
      signups_allowed: false,
      signups_verify: false,
      signups_domains_whitelist: "",
      invitations_allowed: true,
      show_password_hint: false,
      sends_allowed: true,
      emergency_access_allowed: true,
      org_events_enabled: false,
      smtp_from: "",
      smarthost_enabled: false,
      smarthost_host: "",
      ldap_domain: "",
      ldap_domain_list: [],
      ldap_sync_interval: "3600",
      ldap_search_filter: "",
      push_enabled: false,
      push_installation_id: "",
      push_installation_key: "",
      push_relay_uri: "https://push.bitwarden.com",
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        admin_enabled: "",
        admin_password: "",
        signups_allowed: "",
        signups_verify: "",
        signups_domains_whitelist: "",
        invitations_allowed: "",
        show_password_hint: "",
        sends_allowed: "",
        emergency_access_allowed: "",
        org_events_enabled: "",
        smtp_from: "",
        ldap_domain: "",
        ldap_sync_interval: "",
        ldap_search_filter: "",
        push_enabled: "",
        push_installation_id: "",
        push_installation_key: "",
        push_relay_uri: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const config = taskResult.output;

      this.configured = Boolean(config.configured);
      this.host = config.host || "";
      this.lets_encrypt = Boolean(config.lets_encrypt);
      this.http2https =
        config.http2https !== undefined ? Boolean(config.http2https) : true;
      this.admin_enabled =
        config.admin_enabled !== undefined
          ? Boolean(config.admin_enabled)
          : true;
      this.admin_password = "";
      this.signups_allowed = Boolean(config.signups_allowed);
      this.signups_verify = Boolean(config.signups_verify);
      this.signups_domains_whitelist = config.signups_domains_whitelist || "";
      this.invitations_allowed =
        config.invitations_allowed !== undefined
          ? Boolean(config.invitations_allowed)
          : true;
      this.show_password_hint = Boolean(config.show_password_hint);
      this.sends_allowed =
        config.sends_allowed !== undefined
          ? Boolean(config.sends_allowed)
          : true;
      this.emergency_access_allowed =
        config.emergency_access_allowed !== undefined
          ? Boolean(config.emergency_access_allowed)
          : true;
      this.org_events_enabled = Boolean(config.org_events_enabled);
      this.smtp_from = config.smtp_from || "";
      this.smarthost_enabled = Boolean(config.smarthost_enabled);
      this.smarthost_host = config.smarthost_host || "";
      this.ldap_domain = config.ldap_domain || "";
      const domains = Array.isArray(config.ldap_domain_list)
        ? config.ldap_domain_list
        : [];
      this.ldap_domain_list = [
        {
          name: "none",
          label: this.$t("settings.no_ldap_domain"),
          value: "",
        },
        ...domains,
      ];
      this.ldap_sync_interval = String(config.ldap_sync_interval || 3600);
      this.ldap_search_filter = config.ldap_search_filter || "";
      this.push_enabled = Boolean(config.push_enabled);
      this.push_installation_id = config.push_installation_id || "";
      this.push_installation_key = config.push_installation_key || "";
      this.push_relay_uri =
        config.push_relay_uri || "https://push.bitwarden.com";

      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

      if (!this.host) {
        this.error.host = this.$t("common.required");
        if (isValidationOk) {
          this.focusElement("host");
          isValidationOk = false;
        }
      } else if (!this.host.includes(".")) {
        this.error.host = this.$t("settings.invalid_fqdn");
        if (isValidationOk) {
          this.focusElement("host");
          isValidationOk = false;
        }
      }

      if (this.admin_password && this.admin_password.length < 8) {
        this.error.admin_password = this.$t("settings.password_too_short");
        if (isValidationOk) {
          this.focusElement("admin_password");
          isValidationOk = false;
        }
      }

      if (this.ldap_domain) {
        const interval = parseInt(this.ldap_sync_interval, 10);
        if (isNaN(interval) || interval < 60) {
          this.error.ldap_sync_interval = this.$t(
            "settings.invalid_sync_interval"
          );
          if (isValidationOk) {
            this.focusElement("ldap_sync_interval");
            isValidationOk = false;
          }
        }
      }

      if (
        this.smtp_from &&
        (!this.smtp_from.includes("@") || !this.smtp_from.includes("."))
      ) {
        this.error.smtp_from = this.$t("settings.invalid_email");
        this.toggleAccordion = [true];
        if (isValidationOk) {
          this.focusElement("smtp_from");
          isValidationOk = false;
        }
      }

      if (this.push_enabled) {
        if (!this.push_installation_id) {
          this.error.push_installation_id = this.$t("common.required");
          this.toggleAccordion = [true];
          if (isValidationOk) {
            this.focusElement("push_installation_id");
            isValidationOk = false;
          }
        }
        if (!this.push_installation_key) {
          this.error.push_installation_key = this.$t("common.required");
          this.toggleAccordion = [true];
          if (isValidationOk) {
            this.focusElement("push_installation_key");
            isValidationOk = false;
          }
        }
        if (
          this.push_relay_uri &&
          !this.push_relay_uri.startsWith("https://")
        ) {
          this.error.push_relay_uri = this.$t("settings.invalid_https_url");
          this.toggleAccordion = [true];
          if (isValidationOk) {
            this.focusElement("push_relay_uri");
            isValidationOk = false;
          }
        }
      }

      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        this.error[param] = this.$t("settings." + validationError.error);
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );

      const syncInterval = parseInt(this.ldap_sync_interval, 10);

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            http2https: this.http2https,
            lets_encrypt: this.lets_encrypt,
            admin_enabled: this.admin_enabled,
            admin_password: this.admin_password || "",
            signups_allowed: this.signups_allowed,
            signups_verify: this.signups_verify,
            signups_domains_whitelist: this.signups_domains_whitelist || "",
            invitations_allowed: this.invitations_allowed,
            show_password_hint: this.show_password_hint,
            sends_allowed: this.sends_allowed,
            emergency_access_allowed: this.emergency_access_allowed,
            org_events_enabled: this.org_events_enabled,
            smtp_from: this.smtp_from || "",
            ldap_domain: this.ldap_domain || "",
            ldap_sync_interval: isNaN(syncInterval) ? 3600 : syncInterval,
            ldap_search_filter: this.ldap_search_filter || "",
            push_enabled: this.push_enabled,
            push_installation_id: this.push_installation_id || "",
            push_installation_key: this.push_installation_key || "",
            push_relay_uri:
              this.push_relay_uri || "https://push.bitwarden.com",
          },
          extra: {
            title: this.$t("settings.configure_instance", {
              instance: this.instanceName,
            }),
            description: this.$t("common.processing"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";

.mg-bottom-lg {
  margin-bottom: $spacing-06;
}
</style>
