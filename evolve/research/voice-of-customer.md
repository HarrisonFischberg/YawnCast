# Voice of Customer: people who fall asleep to podcasts

Source-type sweep, not tied to any one app. Collected 2026-10-20.

**Method**
- Reddit comments came through the PullPush archive API (`api.pullpush.io`), because reddit.com blocks direct fetches from this environment. Every Reddit URL is the original reddit.com permalink and every date is the comment's `created_utc` (UTC).
- Hacker News comments came from the Algolia API. Dates are `created_at`.
- GitHub issues (AntennaPod, Pocket Casts) came from the GitHub API.
- One Apple Community thread was fetched directly.
- The quotes are exact text. Some are excerpts: "..." marks where text was cut, and nothing inside a quote was rewritten. Light typos are left as written.
- Tags: **complaint** = something that goes wrong today; **missing** = a wish or feature request; **delight** = something people love.
- Anything I could not link and date was dropped. That includes the Spotify Community and featureos pages, whose content would not render.

---

## 1. Autoplay / queue keeps playing all night

**Q1**: "The Up Next "feature" is infuriating. Because, the autoplay next setting is ignored if there's items queued in Up Next. I listen to podcasts to fall asleep sometimes, I don't want it to be still playing when I wake up. ... And sometimes things are added to the list after i've closed my eyes."
- r/ios · https://www.reddit.com/r/ios/comments/1gaeu6x/the_apple_podcast_app_has_to_be_the_singularly/nhoye9b/ · 2025-10-04 · **complaint** · autoplay-next

**Q2**: "I disabled it on my iPhone but for some reason it re-enables itself after a while. ... But then at a different point I might fall asleep with a podcast on and the next morning … it's still playing … and the setting is re-enabled."
- Apple Community, "Apple Podcast App on iOS: continuous play re-enables itself" · https://discussions.apple.com/thread/255556962 · 2024-04-01 · **complaint** · autoplay-next

**Q3**: "What I really want is the ability to have a sleep playlist, since I use podcasts to fall asleep. I hate that if I forget to hit the sleep timer it will automatically play the next in my queue and I’ll have dreams about political news, which no one wants."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1nuhu4n/feature_idea_auto_podcast_playlists/nh6usw9/ · 2025-10-01 · **complaint** · autoplay-next / bedtime-only shows

**Q4**: "I like to fall asleep to podcasts so I need an app that lets you turn off autoplay. I have tried a lot of apps to find the one that works best for me and currently on the apple iOS I like overcast."
- r/GodAwfulMovies · https://www.reddit.com/r/GodAwfulMovies/comments/1t1urf4/what_players_do_you_use/ojjgumq/ · 2026-05-02 · **missing** · autoplay-next

**Q5**: "There have been times when I fall asleep or accidentally start a podcast playing and it just keeps going marking things listened to and arching my whole queue. I’d rather just hit the play button again every hour or so than try to remember to turn on the sleep timer every episode."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/18d70b7/migrating_from_castro_any_advice/kd3ibnh/ · 2023-12-12 · **complaint** · autoplay-next / lost place

**Q6**: "I like to listen while I'm falling asleep, and if I don't set it to stop at the end of the episode it burns through the entire catalogue. And if I turn off continuous play, then selecting every episode at the end of the last one is just a chore."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/9zrwas/have_you_left_pocketcast_as_a_result_of_the_70/eagcrh6/ · 2018-11-25 · **complaint** · autoplay-next

**Q7**: "I have accidentally played podcasts while sleeping that I actually wanted to listen to because I forgot to hit the sleep timer or something and it just kept moving through up next."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1abbbvs/obsessed_with_how_well_ive_organized_my_filter/kjnt7ns/ · 2024-01-26 · **complaint** · autoplay-next / bedtime-only shows

**Q8**: "I fall asleep listening to the intro of the episode I've chosen, only to wake up hours later with the cord to my headphones wrapped multiple times around my neck and the familiar voices of the Small town murder guys still blaring in my ears."
- r/smalltownmurder · https://www.reddit.com/r/smalltownmurder/comments/k6zw0b/time_well_spent/gepdkwr/ · 2020-12-05 · **complaint** · autoplay-next

**Q9**: "But if I don't set the sleep timer, it's onto the next track with a loud and bright BONJOUR, TOI!"
- r/YotoPlayer · https://www.reddit.com/r/YotoPlayer/comments/1ruld92/audio_books_to_for_toddler_to_fall_asleep_to/oauqze8/ · 2026-03-17 · **complaint** · autoplay-next / loud jumps

**Q10**: "I often forget to enable a sleep timer in the evening and when I wake up in the morning my half queue has been played."
- GitHub AntennaPod #2085, "optionally enable the sleep timer always when playing episodes" · https://github.com/AntennaPod/AntennaPod/issues/2085 · 2016-08-02 · **missing** · default-on timer / autoplay-next

## 2. Losing your place; "pick up where I fell asleep"

**Q11**: "you fall asleep, the show rolls on, and you wake up three episodes deep with no clue where you lost the thread."
- r/audiodrama (indie dev, summarizing the thread's top complaint) · https://www.reddit.com/r/audiodrama/comments/1ufgfc4/for_people_who_fall_asleep_to_audio_dramas_i/oxqep4w/ · 2026-07-15 · **complaint** · lost place

**Q12**: "I wish it would allow bookmarking audio. I like to drift off to sleep listening to podcasts. ... say I bookmark a podcast at 20:53, then fall asleep and miss the remainder. I can go back to 20:53 and pick it up from there and be sure I haven't missed anything."
- r/ThisAmericanLife · https://www.reddit.com/r/ThisAmericanLife/comments/1c4p7ku/now_that_google_podcasts_is_gone_and_youtube/kzu06v8/ · 2024-04-16 · **missing** · lost place / sleep bookmark

**Q13**: "I set my sleep timer for 30 min and then the next day rewind to where I fell asleep."
- r/adhdwomen · https://www.reddit.com/r/adhdwomen/comments/1e5qo7b/how_do_you_guys_sleep/ldpxax6/ · 2024-07-18 · **complaint** (manual workaround) · lost place

**Q14**: "The next night I rewind it back to roughly where I fell asleep and start again."
- r/doughboys · https://www.reddit.com/r/doughboys/comments/1wkp7wd/does_anyone_else_use_the_pod_to_fall_asleep_ive/patxm8l/ · 2026-09-19 · **complaint** (manual workaround) · lost place

**Q15**: "I fall asleep listening to it and then the next day, I have to rewind and find my place again."
- r/ADHD · https://www.reddit.com/r/ADHD/comments/1jwn6ws/what_are_things_youve_realised_you_still_cant_do/mmjnv4s/ · 2025-04-11 · **complaint** · lost place

**Q16**: "I often fall asleep to a podcast and then when I wake up I have a hard time finding it because it’s not in in progress and it may be down a ways in new releases."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/wzxdcg/feature_suggestion_filter_by_recently_played/im6ec3e/ · 2022-08-28 · **missing** · lost place / recently played

**Q17**: "if I fall asleep listening to that long list of podcasts that I have queued up, there is not recently listened list so that I can go back and listen to the stuff that I slept through."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/9f1afy/losing_long_up_next_list_after_switching_to_a/e5tmf82/ · 2018-09-12 · **missing** · lost place / recently played

**Q18**: "I fall asleep listening to podcasts and it’s really annoying having to search through the long list of podcasts to replay them"
- r/overcast · https://www.reddit.com/r/overcast/comments/1v4lff6/202671_released_higher_speeds_watch_audio_effects/ozbx08y/ · 2026-07-23 · **complaint** · lost place

**Q19**: "I actually love this and consider it a feature. I listen to podcasts as I go to sleep but always fall asleep before the episode ends, so I set this and I can pop it back 10 mins or whatever when I wake up :D"
- r/pocketcasts (on the end-of-episode timer leaving 0s left instead of marking the episode played) · https://www.reddit.com/r/pocketcasts/comments/a21mfh/when_you_set_a_timer_for_it_to_end_after_an/eaunxyd/ · 2018-12-01 · **delight** · lost place

**Q20**: "Sometimes I want to go back and replay part since I fell asleep early, and this makes it easy. ... I’ve grown to really appreciate it."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/qx9e8l/sleep_timer_end_of_episode_leaves_0s/hl8rzs0/ · 2021-11-19 · **delight** · lost place

**Q21**: "Then I fell asleep and was able to find where I had last heard, I wanted to know something which I didn’t quite hear and scrolled back quickly."
- r/overcast (on transcripts) · https://www.reddit.com/r/overcast/comments/1tobl1o/testflight_build_1157_transcript_text_selection/oo62p1k/ · 2026-05-27 · **delight** · lost place (transcripts, which NightCast deliberately leaves out)

**Q22**: "It used to stop right before the end so that if you fall asleep you're still in the right episode. But it's the second night in a row that when I wake up, it has gone passed the end and on to the next episode ... I have to go history to find my episode that I've missed the end."
- GitHub pocket-casts-android #2266 (user report quoted by the dev team) · https://github.com/Automattic/pocket-casts-android/issues/2266 · 2024-05-21 · **complaint** · lost place / timer reliability

**Q23**: "sleep timers that create bookmarks so that you can remember where you were the next morning."
- Hacker News (indie dev describing an audiobook app) · https://news.ycombinator.com/item?id=47754642 · 2026-04-13 · **delight** · lost place / sleep bookmark

## 3. Fade-out vs. abrupt stop

**Q24**: "I’d be happy with a fade out sleep timer. The sudden volume change wakes me up if I have fallen asleep."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/f9h6p2/would_it_technically_possible_to_set_a_sleep/fisi9zc/ · 2020-02-26 · **missing** · fade-out

**Q25**: "Count me among the happy ones that appreciate that the sleep timer now fades out at the end. I fall asleep while listening to podcasts (10-15 minute timer or so), and I never understood why every other podcast player’s audio faded out gracefully at the end of the timer except Overcast."
- r/overcast · https://www.reddit.com/r/overcast/comments/1veasrx/siracusa_is_saved/p1g8h3i/ · 2026-08-03 · **delight** · fade-out

**Q26**: "Sleep timer fade has been my #1 request since the app was brand new. Came to the Reddit just to say thanks so much!"
- r/overcast · https://www.reddit.com/r/overcast/comments/1vmdb63/20268_released_replay_podcast_smart_complete/p8ty69c/ · 2026-09-09 · **delight** · fade-out

**Q27**: "the smooth fade out means I stay asleep ... as opposed to if the fade out is disabled and there's an abrupt stop instead, which actually often wakes me up because of the suddenness of it."
- r/Podcast_Republic_App · https://www.reddit.com/r/Podcast_Republic_App/comments/1v4esxh/allow_mapping_of_reset_sleep_timer_to/ozbo8vv/ · 2026-07-23 · **delight** · fade-out

**Q28**: "My main reason to join (moving from pocketcast a couple of years ago) was the fading out option of scheduled runtime helping me to fall a sleep."
- r/PodcastAddict · https://www.reddit.com/r/PodcastAddict/comments/1w3q5n2/podcast_addicts_biggest_release_in_10_years_is/p75t7co/ · 2026-09-01 · **delight** · fade-out

**Q29**: "Awesome!! Just one ask: can i please turn off the fading out of the sleep timer? My brain is weird but the fade wakes me up, a hard stop doesn’t."
- r/overcast · https://www.reddit.com/r/overcast/comments/1veyaes/testflight_build_1170_premium_audio_effects/p1ngk0j/ · 2026-08-04 · **missing** · fade-out (dissent)

**Q30**: "I believe now it's 10 seconds, and it's hard to realize that the audio is fading so quickly. There should be an option to customize the time of audio fade-out"
- GitHub AntennaPod #6660 · https://github.com/AntennaPod/AntennaPod/issues/6660 · 2023-09-27 · **missing** · fade-out length

## 4. Still awake when the timer ends: restart or extend without waking up

**Q31**: "My dream feature as a podcast sleeper would be, if you resume a podcast within 60 seconds (or something) of the sleep timer expiring, the timer resets. Currently if my sleep timer stops the playback and I'm still awake, I have to grab my phone, unlock it, go to the setting, and start the timer again. ... Then I wake up next morning and see hours of podcasts played while I was asleep."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/xhj9hd/id_love_a_repeat_option_for_podcasts_from_a/ip2g8vt/ · 2022-09-19 · **missing** · timer auto-restart

**Q32**: "I wish Overcast could restart the sleep timer if playback is activated within five minutes after the timer stops. I often want to continue listening to a podcast, but I have to manually restart the timer, which disrupts my sleep."
- r/overcast · https://www.reddit.com/r/overcast/comments/1veca38/testflight_build_1169_transcript_search_and/p1iaxz3/ · 2026-08-03 · **missing** · timer auto-restart

**Q33**: "if I am AWAKE as it fades out and want to keep listening, I have to quickly reset the timer, or struggle to hear the last minute and a half of the podcast. ... So mapping a Bluetooth/headset control to extending the sleep timer would fix this."
- r/Podcast_Republic_App · https://www.reddit.com/r/Podcast_Republic_App/comments/1v4esxh/allow_mapping_of_reset_sleep_timer_to/ozbo8vv/ · 2026-07-23 · **missing** · timer extend / headphone controls

**Q34**: "Only thing I miss really hard in pocket cast is extending the sleep timer via one press (Castro says „sleep timer extended“)."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/18d70b7/migrating_from_castro_any_advice/kdahljv/ · 2023-12-14 · **missing** · timer extend

**Q35**: "Without the vibrate option enabled in the SleepTimer, it's easy to miss the audio fadeout. This means that the sleep timer sometimes expires when I don't want it to, and I have to unlock my phone and go back into the app to resume playback."
- GitHub AntennaPod #4825 · https://github.com/AntennaPod/AntennaPod/issues/4825 · 2021-01-01 · **complaint** · timer extend

**Q36**: "My sleep is horrible and I use a timer multiple times a night. Setting a timer on my watch would be much less likely to bother my bedmate than rolling over to reach my phone."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1nrw0ij/pocketcasts_its_great/ngrpoi1/ · 2025-09-29 · **missing** · night wakings / partner

## 5. Shake-to-reset: good idea, wakes people when it misfires

**Q37**: "Shake to reset timer is a great idea! But it’s way, way, way too sensitive. The tiniest movement, even just rolling over in bed or picking up the phone to check the time, resets it. So now the sleep timer is useless"
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1d7pm5l/sleep_timer_restarted_due_to_device_shake/l76lkad/ · 2024-06-05 · **complaint** · shake-to-reset

**Q38**: "Sometimes I move my phone when I turn to the other side of the bed, the sound makes me wake up and I don’t want the timer to restart"
- r/pocketcasts (post) · https://www.reddit.com/r/pocketcasts/comments/1d7pm5l/sleep_timer_restarted_due_to_device_shake/ · 2024-06-04 · **complaint** · shake-to-reset / sounds at night

**Q39**: "Not sure how this feature was supposed to work but PING PING PING surely ain’t it."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1d4u3nf/ding_sound_on_ios/l7luyjn/ · 2024-06-07 · **complaint** · shake-to-reset / sounds at night

**Q40**: "it would be great if they add some audio feedback when the sleep timer has been reset via a phone shake. ... so you know the shake worked so you don't have to unlock the phone and look at it to confirm"
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1d2kiuu/sleep_timer_options/l637pb3/ · 2024-05-28 · **missing** · shake-to-reset feedback

**Q41**: "This would be useful for example when you listen to podcast before falling asleep and don't want to have to really shake the phone, but rather just move it to reset the timer."
- GitHub AntennaPod #8093 · https://github.com/AntennaPod/AntennaPod/issues/8093 · 2025-11-14 · **missing** · shake-to-reset

## 6. Loud ads, outros, jingles, and loud jumps

**Q42**: "their ads were WAY louder than the rest of the show. Like if I had my volume up two notches from mute, their ads would sound like it was up by 8 or 9 notches and often woke me up until I quit listening to the show."
- r/assholedesign (thread: "DONT listen to this Podcast if you want to sleep. They contain very loud ads.") · https://www.reddit.com/r/assholedesign/comments/x25lwm/dont_listen_to_this_podcast_if_you_want_to_sleep/imisty5/ · 2022-08-31 · **complaint** · loud ads / normalization

**Q43**: "I often listen when falling asleep and it is jarring to listen to (edit: exceptionally loud) ads or have to open one eye to press skip a few times."
- r/stuffyoushouldknow · https://www.reddit.com/r/stuffyoushouldknow/comments/11sx9qq/psa_if_you_have_youtube_premium_you_can_enjoy_the/jch5ozn/ · 2023-03-16 · **complaint** · loud ads

**Q44**: "What I really don’t like about that one is the excessive ads that are aggressively loud in comparison to the podcast itself. I would love to listen to it falling asleep."
- r/GreekMythology · https://www.reddit.com/r/GreekMythology/comments/1g6i9mu/looking_for_greek_myths_and_tragedies_podcasts/lskwqh6/ · 2024-10-18 · **complaint** · loud ads

**Q45**: "I wish podcasts didn’t have such loud ads."
- r/migraine · https://www.reddit.com/r/migraine/comments/1di107f/amy_cosy_shows_or_films_to_watch_during_a_migraine/l91nqxy/ · 2024-06-17 · **complaint** · loud ads

**Q46**: "I like to fall asleep to podcasts, but it wakes my girlfriend up when the commercials start (especially iHeartRadio commercials!), so I either have it so low I can barely hear or I have to fall asleep to rain/ocean sounds."
- Hacker News · https://news.ycombinator.com/item?id=33991356 · 2022-12-14 · **complaint** · loud ads / partner

**Q47**: "Mainly I want this feature so that loud outros don't wake me up when I fall asleep listening to a podcast."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/bktj1o/stop_playback_early_is_it_possible/emkzv5z/ · 2019-05-05 · **missing** · loud outros

**Q48**: "Please add an outro skipping option, those always wake me up after falling asleep to a podcast."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/a5c4rf/android_beta_v7_1624/ec6ozko/ · 2018-12-20 · **missing** · loud outros

**Q49**: "I have a favorite podcast, that I often fall asleep to. Certain parts with music etc. wake me up. I'd like to chop those parts out as automatically as possible."
- Hacker News · https://news.ycombinator.com/item?id=49932136 · 2026-10-02 · **missing** · loud jumps

**Q50**: "good sound production so everyone is the same volume, and no commercials."
- r/adhdwomen (on what makes a good bedtime show) · https://www.reddit.com/r/adhdwomen/comments/1e5qo7b/how_do_you_guys_sleep/ldpxax6/ · 2024-07-18 · **delight** · normalization

**Q51**: "The only ones that work have a single person talking and no ads intermixed with the podcast episode. Usually I'm asleep five minutes into the podcast."
- Hacker News · https://news.ycombinator.com/item?id=32301486 · 2022-08-01 · **delight** · no ads / bedtime-only shows

**Q52**: "Used to fall asleep listening to Seth Meyers by wow his thememusic is crazy jarring at the end."
- r/Perimenopause · https://www.reddit.com/r/Perimenopause/comments/1whi4qm/what_do_you_listen_to_fall_asleep/pa9023d/ · 2026-09-16 · **complaint** · loud outros

## 7. Volume too loud at its lowest setting

**Q53**: "Lowest volume too loud for me. In this case I am laying in bed with AirPod pro 3s in and even at the lowest volume it is too loud even at the lowest setting to fall asleep to easily."
- r/overcast · https://www.reddit.com/r/overcast/comments/1s9dols/possibility_of_lower_volume/odpj2gd/ · 2026-04-01 · **complaint** · bedtime volume

**Q54**: "when I forget I wake up to a very very loud podcast but it happens every time I don’t set a timer"
- r/alexa · https://www.reddit.com/r/alexa/comments/1wuy74w/random_raising_volume_in_the_night/pdq0hj1/ · 2026-10-04 · **complaint** · bedtime volume / default timer

## 8. Hard to use half-asleep: small, dim UI, too many taps, partner beside you

**Q55**: "I’m already in bed with my reading glasses are off and the phone screen is dimmed when I want to set the sleep timer. ... I go to set the Sleep timer and I see are four blue blobs. I can’t tell what they say without my glasses ... It might say “Stop after 20 minutes”, but I can’t tell because it’s in thin dim text on a grey background."
- r/overcast (post: "Usability Enhancement: Sleep timer for the blurry-eyed") · https://www.reddit.com/r/overcast/comments/1ovm2cg/usability_enhancement_sleep_timer_for_the/ · 2025-11-13 · **complaint** · night legibility

**Q56**: "Unfortunately, that isn’t a good solution when my wife is asleep. ... At that point, it seems it might be best just have an interface that is legible in those situations."
- r/overcast · https://www.reddit.com/r/overcast/comments/1ovm2cg/usability_enhancement_sleep_timer_for_the/nokkpz1/ · 2025-11-13 · **missing** · night legibility / partner

**Q57**: "Two taps to set the sleep timer you want versus opening Overcast, selecting the now playing screen. Tapping the sleep timer button, then fiddling with the timer length buttons. Then dismissing the sleep timer panel."
- r/overcast · https://www.reddit.com/r/overcast/comments/1ovm2cg/usability_enhancement_sleep_timer_for_the/nokzt86/ · 2025-11-13 · **complaint** · taps to start timer

**Q58**: "Something in the settings screen to default a 15 minute sleep timer with a moon icon to click on the main screen."
- r/overcast · https://www.reddit.com/r/overcast/comments/1oubjb9/feature_request_sleep_timer_on_apple_watch/nobcijd/ · 2025-11-11 · **missing** · one-tap timer (close to NightCast's Moon)

**Q59**: "Basic things that should take one tap but take several, like subscribing to/following a podcast, setting a sleep timer, etc. The visuals have gone from simple and clean to fussy and complicated. ... I have no use for playlists, variable speed, etc."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1oqiftq/is_there_an_easy_way_to_transition_from_ovecast/nnm546b/ · 2025-11-07 · **complaint** · taps to start timer / simplicity

**Q60**: "It always feels a bit of a hassle navigating in the app. Specially half asleep/awake."
- r/PodcastAddict · https://www.reddit.com/r/PodcastAddict/comments/1w3q5n2/podcast_addicts_biggest_release_in_10_years_is/p75t7co/ · 2026-09-01 · **complaint** · night usability

**Q61**: "It's a pain, especially at night, when I have to log in to my phone and open Overcast and scroll to find the podcast I was listening to, maybe half a dozen times a night!"
- r/overcast · https://www.reddit.com/r/overcast/comments/1qvpyln/overcast_losing_focus/o3rwbvu/ · 2026-02-05 · **complaint** · night wakings / resume

**Q62**: "The sleep timer button is at the bottom of the screen instead of the top which is hard to reach with one hand"
- r/pocketcasts (listing what they liked about another app) · https://www.reddit.com/r/pocketcasts/comments/1nq6zqt/to_all_the_folks_saying_the_feedback_wasnt_get_us/ng7ztzw/ · 2025-09-26 · **delight** · reachability

**Q63**: "my half asleep brain couldn't make head nor tale of that beta version."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/adm1jl/is_there_a_user_guide_for_this_new_release_of/edi9cuc/ · 2019-01-07 · **complaint** · night usability

**Q64**: "The sleep timer, forward 15 sec and back 15 sec buttons are completely invisible. You have to know where on the screen to press to get to them."
- Hacker News (on Apple Podcasts) · https://news.ycombinator.com/item?id=10680663 · 2015-12-05 · **complaint** · discoverability

## 9. Automatic sleep detection (AirPods, Watch)

**Q65**: "I personally love this feature as I don't need to remember to set a sleep timer so if I'm still for a while (e.g. in bed) and the AirPods think I've fallen asleep, they stop playing."
- r/overcast · https://www.reddit.com/r/overcast/comments/1qp3p8k/app_keeps_on_randomly_pausing_when_have_airpod/p0ulsib/ · 2026-07-31 · **delight** · AirPods sleep detection

**Q66**: "Instead of a sleep timer, I want something that automatically senses when I've fallen asleep and pauses."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1hn1wdv/sleep_timer_issue/m40j0dc/ · 2024-12-27 · **missing** · sleep detection

**Q67**: "I’d be satisfied with a toggle for this option on the now playing screen. I’d use it way more than the sleep timer (especially now that AirPods detect that for me)."
- r/overcast (on stop-after-each-episode) · https://www.reddit.com/r/overcast/comments/1t0bpjo/feature_request_stop_after_each_episode_at/ojf6j5r/ · 2026-05-02 · **missing** · autoplay-next / AirPods

## 10. Bedtime-only shows, kept apart from daytime listening

**Q68**: "I would love to have a sleep playlist that isn’t mixed in with my other pods that I actually want to listen to. While I don’t mind queueing up some sleep podcasts and setting a sleep timer, it means I have to take them off my queue the next morning"
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1ebr62x/pocket_casts_well_needed_features/lewjyxc/ · 2024-07-25 · **missing** · bedtime-only shows

**Q69**: "I have a playlist that I use to fall asleep, ie podcasts I enjoy but don’t mind missing segments; and a separate list for my favorites that I save for dedicated listening"
- r/overcast · https://www.reddit.com/r/overcast/comments/1s14y6n/how_do_you_use_playlists/od7joy2/ · 2026-03-29 · **delight** · bedtime-only shows

**Q70**: "There are some podcasts I listen to as I fall asleep and I’d love just to shuffle through them each night."
- r/overcast · https://www.reddit.com/r/overcast/comments/1tuidet/request_shuffle_option_for_podcasts_and_playlists/opfnh1t/ · 2026-06-03 · **missing** · shuffle a sleep show

**Q71**: "I’d also love an option to play one randomly because I use them to fall asleep to and sometimes I don’t want to decide."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/1k8tnxz/starred_sorting/mp99g2t/ · 2025-04-27 · **missing** · shuffle a sleep show / no decisions

**Q72**: "I have a playlist like this that I use to fall asleep, that way I don’t feel like I’ve missed anything."
- r/overcast (on a playlist of reruns only) · https://www.reddit.com/r/overcast/comments/1p2oqvj/version_2025111_released/npyzw7b/ · 2025-11-21 · **missing** · re-listen comfort shows

## 11. Why they do it: the ritual works

**Q73**: "Now if I'm a bit wound up, I put on some wireless headphones and listen to some really boring or non-consequential podcast with a sleep timer on Overcast. Unless I'm really stressed, I never get to the end of a 10 minute episode."
- Hacker News · https://news.ycombinator.com/item?id=32299039 · 2022-07-31 · **delight** · ritual / short timers

**Q74**: "My routine is to play a podcast that I am interested in, put a sleep timer on 20 min (Overcast app FTW), and just enjoy the content. ... What makes it funny is I will be listening a single episode for weeks sometime, often listening the same parts over and over again"
- Hacker News · https://news.ycombinator.com/item?id=48706422 · 2026-06-28 · **delight** · ritual / lost place

**Q75**: "I'd play the podcast in one ear with the other on my pillow with a 30-minute sleep timer and play it over several nights until the next episode came out."
- Hacker News · https://news.ycombinator.com/item?id=49014030 · 2026-07-22 · **delight** · ritual / one ear

**Q76**: "the timer was key because i knew it would cut off so i didn't have to make that decision half-asleep."
- r/sleep · https://www.reddit.com/r/sleep/comments/1wfch8v/middle_of_the_night_waking_advice/pednfrl/ · 2026-10-07 · **delight** · no decisions at night

**Q77**: "I set the sleep timer for 15 minutes and never hear it fade out."
- r/AskReddit · https://www.reddit.com/r/AskReddit/comments/1p2uw08/what_have_you_found_that_helps_you_sleep_when_you/nq14hji/ · 2025-11-21 · **delight** · fade-out / ritual

**Q78**: "I'd prefer one minute. I pretty much fall asleep to the app every night, and I find ten minutes too long and five minutes to short. Usually eight is that sweet spot."
- r/pocketcasts (on timer step size) · https://www.reddit.com/r/pocketcasts/comments/9xpqah/will_there_ever_be_a_way_to_revert_to_an_older_ui/ebnv3z6/ · 2018-12-12 · **missing** · custom timer length

## 12. Sleep timer reliability and other night-time bugs

**Q79**: "Sleep timer rarely works. I set it to 25 minutes but it’s still playing after that time. I can’t rely on it."
- GitHub pocket-casts-android #2219 (user report quoted by the dev team) · https://github.com/Automattic/pocket-casts-android/issues/2219 · 2024-05-13 · **complaint** · timer reliability

**Q80**: "the most recently played podcast will restart an hour or two after the sleep timer stops it. Since I use this feature to fall asleep, having the podcast suddenly restart wakes m[e]"
- GitHub pocket-casts-android #141 (user report quoted by the dev team) · https://github.com/Automattic/pocket-casts-android/issues/141 · 2022-07-20 · **complaint** · timer reliability

**Q81**: "When you start a podcast on the iPhone, and then stream it to the HomePod, you lose the ability to set a Sleep Timer within the podcasts app (it’s greyed out)."
- Apple Community · https://discussions.apple.com/thread/252057007 · 2020-11-17 · **complaint** · speaker / AirPlay timer

**Q82**: "When my AntennaPod goes to sleep, and I am asleep already, I would like my phone to disconnect from my speaker, so it can also turn off automatically, and save battery energy"
- GitHub AntennaPod #7797 · https://github.com/AntennaPod/AntennaPod/issues/7797 · 2025-05-03 · **missing** · Bluetooth after timer

**Q83**: "I have a Wonderboom speaker and it makes a very loud sound when turning on an off which can't be deactivated. That's absolute hell when using it for listening to podcasts while falling asleep."
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/ebfj2q/enquiry_whats_the_best_bluetooth_speaker_suited/fb4i128/ · 2019-12-16 · **complaint** · sounds at night / Bluetooth

**Q84**: "It's the only thing I listen to at night before I fall asleep. Start at 100% before bed and wake up to 60%."
- r/overcast · https://www.reddit.com/r/overcast/comments/1t55axj/overcast_battery_usage/okbfgoi/ · 2026-05-06 · **complaint** · overnight battery

**Q85**: "my top podcasts were ones I play to fall asleep to, not ones I actively listen to, oops. Wish I could see what it was if I excluded a couple playlists"
- r/pocketcasts · https://www.reddit.com/r/pocketcasts/comments/z8rlqe/pocket_casts_added_a_year_in_review_section/iygbcqk/ · 2022-12-01 · **complaint** · stats skewed by sleep

**Q86**: "Also sometimes I fall asleep in bed with them while listening to a podcast, and have experienced the same painfully loud screeching as described by the article when the microphones brush against the pillow"
- Hacker News · https://news.ycombinator.com/item?id=45734506 · 2025-10-28 · **complaint** · AirPods in bed

---

## Theme table

| Theme | Tag | Count | Strongest refs |
|---|---|---|---|
| Autoplay-next / queue runs all night | complaint | 10 (Q1-Q10) | Q1, Q3 |
| Lost place / "where did I fall asleep" | complaint + missing | 9 (Q11-Q18, Q22) | Q11, Q12 |
| Lost place is easy to recover (timer leaves the episode, bookmark) | delight | 4 (Q19-Q21, Q23) | Q19, Q23 |
| Fade-out instead of an abrupt stop | delight + missing | 6 (Q24-Q28, Q77) | Q24, Q27 |
| Fade-out dissent: fade wakes me / fade too short | missing | 2 (Q29, Q30) | Q29 |
| Timer auto-restart / extend while still awake | missing | 6 (Q31-Q36) | Q31, Q32 |
| Shake-to-reset misfires and makes noise | complaint + missing | 5 (Q37-Q41) | Q37, Q38 |
| Loud ads / outros / music stings wake you | complaint + missing | 9 (Q42-Q49, Q52) | Q42, Q47 |
| Even volume / no ads makes a good sleep show | delight | 2 (Q50, Q51) | Q51 |
| Minimum volume too loud | complaint | 2 (Q53, Q54) | Q53 |
| Hard to read or operate half-asleep (dim, small, too many taps) | complaint | 7 (Q55, Q57, Q59-Q61, Q63, Q64) | Q55, Q57 |
| One-tap / legible / reachable timer wanted | missing + delight | 3 (Q56, Q58, Q62) | Q58 |
| Partner asleep nearby | complaint + missing | 3 (Q36, Q46, Q56) | Q46 |
| Automatic sleep detection (AirPods / Watch) | delight + missing | 3 (Q65-Q67) | Q65, Q66 |
| Bedtime-only shows kept apart from daytime ones | missing + delight | 3 (Q68, Q69, Q72) | Q68 |
| Shuffle / "don't make me choose" at night | missing | 2 (Q70, Q71) | Q71 |
| The ritual works; short timers, one ear | delight | 4 (Q73-Q76) | Q73, Q76 |
| Custom timer length | missing | 1 (Q78) | Q78 |
| Timer reliability bugs (keeps playing, restarts) | complaint | 2 (Q79, Q80) | Q80 |
| Speaker / Bluetooth / AirPlay behaviour at night | complaint + missing | 3 (Q81-Q83) | Q81 |
| Overnight battery drain | complaint | 1 (Q84) | Q84 |
| Stats skewed by sleep listening | complaint | 1 (Q85) | Q85 |
| AirPods hardware discomfort in bed | complaint | 1 (Q86) | Q86 |

Some quotes fit more than one theme, so the counts overlap a little. There are 86 quotes in all.

**How this lines up with NightCast** (my reading, not part of the evidence):
- NightCast's fixed "no autoplay-next" rule speaks directly to the largest complaint cluster.
- The Moon timer's ~6-minute fade sits with the majority on fade (Q24-Q28). Q29 is a minority who want a hard stop.
- The biggest gaps the quotes point at are:
  - "Back to where I fell asleep" (Q11-Q18), for example a bookmark at the moment the fade starts.
  - A no-hassle restart when still awake (Q31-Q35).
  - Night legibility, meaning large high-contrast controls (Q55-Q57).
- Loud ads and outros (Q42-Q49) are partly solvable with player-side volume leveling. The "no speed control" and "no transcripts" choices clash with only one quote each (Q21; speed comes up only in passing in Q59).

## Injected instructions seen

None. No fetched page or post contained instructions directed at an agent.
