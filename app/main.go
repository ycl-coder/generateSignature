// main.go
package main

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"net/http"
)

type Request struct {
	StringToSign string `json:"stringToSign"`
	SecretKey    string `json:"secretKey"`
}

type Response struct {
	Signature string `json:"signature"`
	Error     string `json:"error,omitempty"`
}

func GenerateSignature(w http.ResponseWriter, r *http.Request) {
	var req Request
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.StringToSign == "" || req.SecretKey == "" {
		respondError(w, "Missing parameters", http.StatusBadRequest)
		return
	}

	// 生成 HMAC-SHA1 签名
	h := hmac.New(sha1.New, []byte(req.SecretKey))
	h.Write([]byte(req.StringToSign))
	signature := base64.StdEncoding.EncodeToString(h.Sum(nil))

	json.NewEncoder(w).Encode(Response{Signature: signature})
}

func respondError(w http.ResponseWriter, message string, code int) {
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(Response{Error: message})
}

func main() {
	http.HandleFunc("/", GenerateSignature)
	http.ListenAndServe(":8080", nil)
}
