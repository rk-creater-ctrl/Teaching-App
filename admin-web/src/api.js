// src/api.js
import axios from "axios";
import { API_URL } from "./config";

const api = axios.create({
  baseURL: API_URL,
});

api.interceptors.request.use((config) => {
  const admin = JSON.parse(localStorage.getItem("admin") || "null");
  if (admin?.token) {
    config.headers.Authorization = `Bearer ${admin.token}`;
  }
  return config;
});

export default api;
