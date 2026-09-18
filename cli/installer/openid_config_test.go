package installer

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestOpenIDConfigCarriesTheRegisteredTokenAuthMethod(t *testing.T) {
	raw, err := OpenIDConfig("https://auth.example.com", "paperless", "secret")
	assert.NoError(t, err)

	var config Config
	assert.NoError(t, json.Unmarshal([]byte(raw), &config))
	assert.Len(t, config.Connect.Apps, 1)

	app := config.Connect.Apps[0]
	assert.Equal(t, "paperless", app.ClientID)
	assert.Equal(t, "https://auth.example.com", app.Settings.ServerURL)
	assert.Equal(t, TokenAuthMethod, app.Settings.TokenAuthMethod)
	assert.Contains(t, config.Connect.Scope, "groups")
}
