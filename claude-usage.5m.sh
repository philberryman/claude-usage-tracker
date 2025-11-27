#!/bin/bash

# <xbar.title>Claude Code Usage</xbar.title>
# <xbar.version>v2.2</xbar.version>
# <xbar.author>Phil Berryman</xbar.author>
# <xbar.author.github>philberryman</xbar.author.github>
# <xbar.desc>Shows Claude Code API usage limits in the menu bar</xbar.desc>
# <xbar.dependencies>bun</xbar.dependencies>

export PATH="/opt/homebrew/bin:$PATH"

bun -e '
import { $ } from "bun";

interface UsageData {
  five_hour: { utilization: number; resets_at: string };
  seven_day: { utilization: number; resets_at: string };
  seven_day_sonnet?: { utilization: number; resets_at: string } | null;
  seven_day_opus?: { utilization: number; resets_at: string | null } | null;
  extra_usage?: {
    is_enabled: boolean;
    monthly_limit: number | null;
    used_credits: number | null;
    utilization: number | null;
  };
}

function formatTime(resetDate: string | null): string {
  if (!resetDate) return "N/A";
  const diffMs = new Date(resetDate).getTime() - Date.now();
  if (diffMs <= 0) return "now";
  const mins = Math.floor(diffMs / 60000);
  const hrs = Math.floor(mins / 60);
  const days = Math.floor(hrs / 24);
  if (days > 0) return `${days}d ${hrs % 24}h`;
  if (hrs > 0) return `${hrs}h ${mins % 60}m`;
  return `${mins}m`;
}

function getMinutesUntilReset(resetDate: string): number {
  const diffMs = new Date(resetDate).getTime() - Date.now();
  return Math.max(0, Math.floor(diffMs / 60000));
}

// Weekly: green if below 15%/day pace for weekdays (saves 25% for weekends)
function getWeeklyStatus(utilization: number, resetsAt: string): { emoji: string; color: string } {
  const reset = new Date(resetsAt);
  const msRemaining = reset.getTime() - Date.now();
  const daysRemaining = msRemaining / (1000 * 60 * 60 * 24);
  const daysElapsed = 7 - daysRemaining;
  const targetPerDay = 15;
  const idealUsage = daysElapsed * targetPerDay;

  if (utilization <= idealUsage) return { emoji: "🟢", color: "green" };
  if (utilization <= idealUsage + 10) return { emoji: "🟡", color: "orange" };
  return { emoji: "🔴", color: "red" };
}

// Session (5hr): based on how far through the window
function getSessionStatus(utilization: number, resetsAt: string): { emoji: string; color: string } {
  const minsRemaining = getMinutesUntilReset(resetsAt);
  const totalMins = 5 * 60;
  const minsElapsed = totalMins - minsRemaining;
  const timeProgress = (minsElapsed / totalMins) * 100;

  const buffer = 10;
  if (utilization >= 80 && utilization > timeProgress + buffer) {
    return { emoji: "🔴", color: "red" };
  }
  if (utilization > timeProgress + 20) {
    return { emoji: "🟡", color: "orange" };
  }
  return { emoji: "🟢", color: "green" };
}

try {
  const creds = JSON.parse(await $`security find-generic-password -s "Claude Code-credentials" -w`.text());
  const token = creds.claudeAiOauth?.accessToken;
  if (!token) throw new Error("No token");

  const res = await fetch("https://api.anthropic.com/api/oauth/usage", {
    headers: {
      Authorization: `Bearer ${token}`,
      "anthropic-beta": "oauth-2025-04-20",
      "User-Agent": "claude-code/2.0.54",
    },
  });

  if (!res.ok) throw new Error(`API ${res.status}`);
  const data: UsageData = await res.json();

  const u5 = data.five_hour.utilization;
  const u7 = data.seven_day.utilization;
  const uSonnet = data.seven_day_sonnet?.utilization ?? 0;

  const weekly = getWeeklyStatus(u7, data.seven_day.resets_at);
  const session = getSessionStatus(u5, data.five_hour.resets_at);

  // Menu bar: show weekly and session indicators
  console.log(`${weekly.emoji}${Math.round(u7)}% ${session.emoji}${Math.round(u5)}%`);
  console.log("---");

  // Weekly details (main limit - includes Opus)
  console.log(`Weekly: ${Math.round(u7)}% (resets ${formatTime(data.seven_day.resets_at)}) | color=${weekly.color}`);
  console.log(`-- Target: 15%/weekday, 25% for weekends | color=gray`);

  // Sonnet (separate limit)
  if (data.seven_day_sonnet) {
    const sonnetColor = uSonnet > 90 ? "red" : uSonnet > 70 ? "orange" : "green";
    console.log(`Sonnet: ${Math.round(uSonnet)}% (resets ${formatTime(data.seven_day_sonnet.resets_at)}) | color=${sonnetColor}`);
  }

  console.log("---");

  // Session details
  console.log(`Session: ${Math.round(u5)}% (resets ${formatTime(data.five_hour.resets_at)}) | color=${session.color}`);
  const minsRemaining = getMinutesUntilReset(data.five_hour.resets_at);
  const timeUsed = Math.round(((300 - minsRemaining) / 300) * 100);
  console.log(`-- Time elapsed: ${timeUsed}% | color=gray`);

  // Extra usage info if enabled
  if (data.extra_usage?.is_enabled && data.extra_usage.utilization !== null) {
    console.log("---");
    console.log(`Extra Usage: ${Math.round(data.extra_usage.utilization)}% | color=blue`);
  }

  console.log("---");
  console.log("Open Claude | href=https://claude.ai");
  console.log("Usage Settings | href=https://claude.ai/settings/usage");
  console.log("---");
  console.log("Refresh | refresh=true");
} catch (e) {
  console.log("⚠️");
  console.log("---");
  console.log(`Error: ${e.message} | color=red`);
}
'
