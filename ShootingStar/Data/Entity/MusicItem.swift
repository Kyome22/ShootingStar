/*
  MusicItem.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import MediaPlayer

struct MusicItem: Identifiable, Equatable {
    let id: String
    let assetURL: URL?
    let title: String?
}
