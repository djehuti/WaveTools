//
//  WaveToolsLocalization.h
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <WaveTools/WaveToolsBundleUtils.h>


#define DWTLocalizedString(key, comment) \
    [DWTWaveToolsBundle() localizedStringForKey:(key) value:@"" table:@"WaveTools"]

#define DWTLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
    [DWTWaveToolsbundle() localizedStringForKey:(key) value:(val) table:@"WaveTools"]
