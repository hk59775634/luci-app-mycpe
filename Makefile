include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-myCPE
PKG_VERSION=1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=luci
    CATEGORY:=LuCI
    SUBMENU:=3. Applications
    TITLE:=myCPE for LuCI
    PKGARCH:=all
    DEPENDS:= 
endef

define Package/$(PKG_NAME)/description
    This package contains LuCI configuration pages for myCPE.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
    $(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)/postinst
	killall mycpe
    /etc/init.d/mycpe start
    rm -f /tmp/luci-indexcache  >/dev/null 2>&1
endef

define Package/$(PKG_NAME)/postrm
	killall mycpe
    rm -f /tmp/luci-indexcache  >/dev/null 2>&1
endef

$(eval $(call BuildPackage,$(PKG_NAME)))